$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'httparty'
require 'json'

module GitHubBackup
  class << self
    def require_all
      Dir[File.join(File.dirname(__FILE__), %W(** *.rb))].each do |f|
        require f unless f == File.expand_path(__FILE__)
      end
    end

    def main
      require_all
      backup
    end

    def backup
      GitHubBackup::Options.parse
      opts = GitHubBackup::Options.options

      GitHubBackup::GitHub.options = opts
      GitHubBackup::GitHub.backup_repos
    end

  end
end

GitHubBackup.main