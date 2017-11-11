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
		@calendar = Google::Apis::CalendarV3::CalendarService.new
		@calendar.client_options.application_name = Config::APPLICATION_NAME
		@calendar.authorization = authorize_calendar
	end

	def scan_emails
		gmail = Gmail.connect!(Config::UNAME, Config::PWORD)
		gmail.inbox.emails(:after => DateTime.now - 20) do |mail|
		  subject = mail.message.subject
			next unless subject.downcase.start_with?("hold the date:") || subject.downcase.start_with?("gig confirmation")
			process_gig(mail)
		end
		gmail.logout
	end

	private

	def process_gig(mail)
		array = mail.message.subject.sub(',', '').split(':')
    band = array[1]
    date = Date.parse(array[2].split[0...4].join(' '))
    make_event(date, band, mail)
	end

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

	def event_exists?(data, band)
		exists = false
		events = fetch_events_by_day(data.date)
		events.each do |event|
			uid = event.summary.match(/UID:(\d+)/)
			next unless uid
			# BUG, uid makes use of curfew and load in times when in fact these can change between 
			# hold the date and confirmation emails.
			exists =  true if event.summary.include?(band) && uid[1].to_i == data.uid
		end
		if exists
			STDERR.puts("Not creating event #{data.uid} as it already exists")
		end
		exists
	end

	def fetch_events_by_day(date)
		@calendar.list_events(Config::CALENDAR_ID,
		  max_results: 10,
		  single_events: true,
		  order_by: 'startTime',
		  time_min: date.to_time.iso8601,
		  time_max: (date + 1).to_time.iso8601
		 ).items
	end

	def make_event(date, band, mail)
	  data = EventData.new(date, mail, band)
	  unless event_exists?(data, band)
		  resource = Google::Apis::CalendarV3::Event.new({
		      summary: data.summary,
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
		  result = @calendar.insert_event(Config::CALENDAR_ID, resource)
		  puts "Event created for #{band} on #{date.to_s} #{result.html_link}"
		  puts data.summary
		end
	end
end
