require 'optparse'

module GitHubBackup
  class Options
    class << self
      attr_accessor :options

      def parse
        self.options ||= {}

        optparse = OptionParser.new do |opts|

          opts.banner = "Usage: github-backup -u [username] -o [dir]
e.g
github-backup -u hbt -o /tmp \n\n"


          opts.on('-u', '--username USERNAME', '*Required: GitHub username') do |f|
            self.options[:username] = f
          end

          opts.on('-o', '--output-dir DIR', '*Required: Backup directory') do |f|
            self.options[:bakdir] = File.expand_path(f)
          end

          opts.on('-p', '--password PASSWORD', 'Optional: GitHub password. Required for private repos') do |f|
            self.options[:passwd] = f
          end

          opts.on('-O', '--organization ORGANIZATION_NAME', 'Optional: Organization name of the organization to fetch repositories from') do |f|
            self.options[:organization] = f
          end

          opts.on('-r', '--repository-name NAME', 'Optional: limit to this repository name') do |f|
            self.options[:reponame] = f
          end

          opts.on('-f', '--forks', 'Optional: fetch all forks') do
            self.options[:forks] = true
          end

          opts.on('-F', '--skip-forked', 'Optional: skip forked repositories.') do
            self.options[:skip_forked] = true
          end

          opts.on('-i', '--dump-issues', 'Optional: dump all issues into a file') do
            self.options[:issues] = true
          end

          opts.on('-w', '--wiki', 'Optional: clone repository wiki') do
            self.options[:wiki] = true
          end

          opts.on('-D', '--debug', 'Optional: enable logging debug messages') do
            self.options[:debug] = true
          end

          opts.on('-v', '--version', 'Displays current version ') do
            version = File.expand_path(File.dirname(__FILE__) + '../../../VERSION')
            puts "Version: " + File.read(version)[0...-1] if File.exists? version
            exit
          end

          opts.on('-h', '--help', 'Displays this screen') do
            puts opts
            exit
          end
        end

        optparse.parse!

        if !is_valid?
          puts optparse
          exit
        end
      end

      # check required options
      def is_valid?
        return false unless self.options[:bakdir] && File.exists?(self.options[:bakdir])
        return false unless self.options[:username]
        true
      end

    end
  end
end
