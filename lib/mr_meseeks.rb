require 'gmail'
require 'date'
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'json'
require 'fileutils'
require 'pry'
require_relative 'config.rb'

########################
#  AWFUL MONKEY PATCH  #
########################
class Object
  def to_imap_date
    date = respond_to?(:utc) ? utc.to_s : to_s
    Date.parse(date).strftime("%d-%b-%Y")
  end
end
######################
#  END MONKEY PATCH  #
######################

class MrMeseeks
	def initialize
		# Initialize the API
		$calendar = Google::Apis::CalendarV3::CalendarService.new
		$calendar.client_options.application_name = Config::APPLICATION_NAME
		$calendar.authorization = authorize_calendar
	end

	def scan_emails
		gmail = Gmail.connect!(Config::UNAME, Config::PWORD)
		gmail.inbox.emails(:after => (DateTime.now - 20).to_imap_date) do |mail|
		  if mail.message.subject.start_with?("Hold The Date:")
		    array = mail.message.subject.sub(',', '').split(':')
		    band = array[1]
		    date = Date.parse(array[2].split[0...4].join(' '))
		    make_event(date, band, mail)
		  end
		end
		gmail.logout
	end

	private

	def authorize_calendar
		oob_uri = 'urn:ietf:wg:oauth:2.0:oob'
		scope = Google::Apis::CalendarV3::AUTH_CALENDAR
		
		FileUtils.mkdir_p(File.dirname(Config::CREDENTIALS_PATH))

	  client_id = Google::Auth::ClientId.from_file(Config::CLIENT_SECRETS_PATH)
	  token_store = Google::Auth::Stores::FileTokenStore.new(file: Config::CREDENTIALS_PATH)
	  authorizer = Google::Auth::UserAuthorizer.new(
	    client_id, scope, token_store)
	  user_id = 'default'
	  credentials = authorizer.get_credentials(user_id)
	  if credentials.nil?
	    url = authorizer.get_authorization_url(
	      base_url: oob_uri)
	    puts "Open the following URL in the browser and enter the " +
	         "resulting code after authorization"
	    puts url
	    code = gets
	    credentials = authorizer.get_and_store_credentials_from_code(
	      user_id: user_id, code: code, base_url: oob_uri)
	  end
  	credentials
	end 

	def make_event(date, band, mail)
	  data = extract_data(date, mail)
	  calendar_id = Config::CALENDAR_ID
	  resource = Google::Apis::CalendarV3::Event.new({
	      summary: "#{band} GIG",
	      location: data[:location],
	      start: {
	        date_time: data[:load_in],
	        time_zone: 'Europe/London',
	      },
	      end: {
	        date_time: data[:curfew],
	        time_zone: 'Europe/London',
	      }
	  })
	  binding.pry
	  result = $calendar.insert_event(calendar_id, resource)
	  puts "Event created: #{result.html_link}"
	end

	# This belongs in its own class really

	def extract_data(date, mail)
		msg_body = mail.message.body.to_s
		data = {
			load_in: fetch_load_in(msg_body, date),
			curfew: fetch_curfew(msg_body, date),
			location: fetch_location(msg_body)
		}
	end

	def fetch_load_in(message, date)
		match = message.match(/Arrival Time:\r\n(\d{2}:\d{2})/)
		if match
			result = create_datetime(date, match[1])
		else
			result = create_datetime(date, "17:00")
		end
	end

	def fetch_curfew(message, date)
		match = message.match(/Curfew:\r\n(\d{2}:\d{2})/)
		# HUGE UNSAFE ASSUMPTION HERE, WILL BREAK ON THE DEFAULTS
		# SORT THIS NEXT
		load_in = message.match(/Arrival Time:\r\n(\d{2}:\d{2})/)

		if match
			if match[1] < load_in[1]
				result = create_datetime((date + 1), match[1])
			else
				result = create_datetime(date, match[1])				
			end
		else
			result = create_datetime(date, "23:59")
		end
	end

	def fetch_location(message)
		match = message.match(/Venue:\r\n(.+)/)
		if match
			result = match[1].sub("\r", "")
		else
			result = "TBC"
		end
	end

	def create_datetime(date, modifier)
		# This is ugly Ken
		(date.to_time + seconds_since_midnight(modifier)).to_datetime.to_s
	end

	def seconds_since_midnight(time_string)
		time = Time.parse(time_string)
		(time.hour * 60 * 60) + (time.min * 60) + (time.sec)
	end
end
