require 'yaml'

module Config
  data = YAML.load_file('./config/secrets.yml')
  UNAME = ENV['GMAIL_UNAME']
  PWORD = ENV['GMAIL_PWORD']
  APPLICATION_NAME = 'NellyMail'
  CLIENT_SECRETS_PATH = data['client_secrets_path']
  CREDENTIALS_PATH = data['credentials_path']
  CALENDAR_ID = data['calendar_id']
end