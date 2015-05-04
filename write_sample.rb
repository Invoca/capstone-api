require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'

APPLICATION_NAME = "Calendar API Sample"
CLIENT_SECRETS_PATH = "./client_secret.json"
OAUTH_TOKEN_STORAGE_PATH = "./calendar-api-sample.json"
SCOPE = "https://www.googleapis.com/auth/calendar"

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization request via InstalledAppFlow.
# If authorization is required, the user's default browser will be launched
# to approve the request.
#
# @return [Signet::OAuth2::Client] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(OAUTH_TOKEN_STORAGE_PATH))

  file_store = Google::APIClient::FileStore.new(OAUTH_TOKEN_STORAGE_PATH)
  oauth_storage = Google::APIClient::Storage.new(file_store)
  oauth = oauth_storage.authorize

  if oauth.nil? || (oauth.expired? && oauth.refresh_token.nil?)
    app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
    flow = Google::APIClient::InstalledAppFlow.new(
      client_id:     app_info.client_id,
      client_secret: app_info.client_secret,
      scope:         SCOPE
    )
    if oauth = flow.authorize(oauth_storage)
      puts "Credentials saved to #{OAUTH_TOKEN_STORAGE_PATH}"
    end
  end
  oauth
end

ARGV.size > 0 or raise "pass quickAdd string on command line"
quick_add = ARGV.join(' ')

client = Google::APIClient.new(application_name: APPLICATION_NAME)
calendar_api = client.discovered_api('calendar', 'v3')
client.authorization = authorize

# Fetch the next 10 events for the user
results = client.execute!(
  api_method:  calendar_api.events.quick_add,
  parameters:  {
    calendarId: "primary",
    text:       quick_add
  }
)

puts "Added!"
