require_relative 'config.rb'
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'


class CalendarService
	attr_accessor :calendar
	
	def initialize
		@calendar = Google::Apis::CalendarV3::CalendarService.new
		@calendar.client_options.application_name = Config::APPLICATION_NAME
		@calendar.authorization = authorize_calendar
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
end