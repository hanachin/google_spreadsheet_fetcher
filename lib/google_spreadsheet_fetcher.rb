require "google_spreadsheet_fetcher/version"
require "google_spreadsheet_fetcher/config"
require "google_spreadsheet_fetcher/fetcher"

module GoogleSpreadsheetFetcher
  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end
end
