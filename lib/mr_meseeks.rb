require 'gmail'
require 'date'
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'json'
require 'fileutils'
require 'pry'
require_relative 'config.rb'
require_relative 'event_data.rb'
require_relative 'patches/object.rb'

class MrMeseeks
	def initialize
		# Initialize the API
		$calendar = Google::Apis::CalendarV3::CalendarService.new
		$calendar.client_options.application_name = Config::APPLICATION_NAME
		$calendar.authorization = authorize_calendar
	end

	def scan_emails
		gmail = Gmail.connect!(Config::UNAME, Config::PWORD)
		gmail.inbox.emails(:after => DateTime.now - 20) do |mail|
		  if mail.message.subject.start_with?("Hold The Date:")
		    array = mail.message.subject.sub(',', '').split(':')
		    band = array[1]
		    date = Date.parse(array[2].split[0...4].join(' '))
		    message = mail.message.body.to_s
		    make_event(date, band, message)
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

	def make_event(date, band, message)
	  data = EventData.new(date, message)
	  resource = Google::Apis::CalendarV3::Event.new({
	      summary: "#{band} GIG",
	      location: data.location,
	      start: {
	        date_time: data.load_in,
	        time_zone: 'Europe/London',
	      },
	      end: {
	        date_time: data.curfew,
	        time_zone: 'Europe/London',
	      }
	  })
	  result = $calendar.insert_event(Config::CALENDAR_ID, resource)
	  puts "Event created: #{result.html_link}"
	end
end
