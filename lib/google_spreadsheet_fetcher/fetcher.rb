require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/drive_v2'
require 'google_drive'
require 'shellwords'

module GoogleSpreadsheetFetcher
  class Fetcher
    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

    def initialize(credential_store_file, user_id, sheet_key)
      @client_secret_file = GoogleSpreadsheetFetcher.config.client_secrets_file_path
      @credential_store_file = credential_store_file
      @user_id = user_id
      @sheet_key = sheet_key
    end

    def fetch_by_index(index)
      fetch_worksheet_by(index: index)
    end

    def fetch_by_title(title)
      fetch_worksheet_by(title: title)
    end

    def fetch_by_gid(gid)
      fetch_worksheet_by(gid: gid)
    end

    private

    def fetch_worksheet_by(index: nil, title: nil, gid: nil)
      credentials = fetch_credentials

      drive = Google::Apis::DriveV2::DriveService.new
      drive.authorization = credentials
      session = GoogleDrive::Session.login_with_oauth(credentials)

      spreadsheet = session.spreadsheet_by_key(@sheet_key)

      unless index.nil?
        return spreadsheet.worksheets[index]
      end

      unless title.nil?
        return spreadsheet.worksheet_by_title(title)
      end

      unless gid.nil?
        return spreadsheet.worksheet_by_gid(gid)
      end

      raise
    end

    def fetch_credentials
      oob_uri = 'urn:ietf:wg:oauth:2.0:oob'

      client_id = Google::Auth::ClientId.from_file(@client_secret_file)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: @credential_store_file)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, scopes, token_store)

      credentials = authorizer.get_credentials(@user_id)

      if credentials.nil?
        url = authorizer.get_authorization_url(base_url: OOB_URI)
        escaped_url = url.shellescape
        system("open #{escaped_url}")
        puts "Open #{url} in your browser and enter the resulting code: "
        code = STDIN.gets
        credentials = authorizer.get_and_store_credentials_from_code(user_id: @user_id, code: code, base_url: oob_uri)
      end

      credentials
    end

    def scopes
      %w[
        https://spreadsheets.google.com/feeds/
        https://www.googleapis.com/auth/drive
        https://www.googleapis.com/auth/userinfo.profile
      ]
    end
  end
end
