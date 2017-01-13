require 'fileutils'
require 'pp'
require 'logger'

module GitHubBackup
  module GitHub
    class << self
      attr_accessor :opts, :logger

      def options=(v)
        self.opts = v
        self.logger = Logger.new STDOUT
        logger.level = Logger::INFO
        logger.level = Logger::DEBUG if opts[:debug]
        self.logger.formatter = proc do |severity, datetime, progname, msg|
          if logger.level == Logger::DEBUG
            # from http://stackoverflow.com/questions/15852570/in-ruby-can-one-put-the-file-and-line-number-into-the-logger-formatter
            fileLine = ""
            caller.each do |clr|
              unless (/\/logger.rb:/ =~ clr)
                fileLine = clr
                break
              end
            end
            fileLine = fileLine.split(':in `', 2)[0]
            fileLine.sub!(/:(\d)/, '(\1')
            fileLine.gsub!(File.dirname(__FILE__), '')

            datetime = datetime.strftime "%T"
            "#{datetime} #{severity} #{fileLine}) : #{msg}\n"
          else
            datetime = datetime.strftime "%Y-%m-%d %T"
            "#{datetime} #{severity} : #{msg}\n"
          end

        end
        logger.debug opts
      end

      def backup_repos()
        # get all repos
        (1..100).each do |i|
          if opts[:organization]
            url = "/orgs/#{opts[:organization]}/repos"
          elsif opts[:passwd]
            url ="/user/repos"
          else
            url = "/users/#{opts[:username]}/repos"
          end
          repos = json("#{url}?page=#{i}&per_page=100")
          repos.each do |f|
            # do we limit to a specific repo?
            next unless f['name'] == opts[:reponame] if opts[:reponame]
            # // TODO(hbt) ENHANCE merge skip-forked
            backup_repo f
          end
          break if repos.size == 0
        end

      end

      def backup_repo(repo)
        Dir.chdir(opts[:bakdir])

        logger.info "backup repository #{repo['full_name']}"

        repo['repo_path'] = "#{opts[:bakdir]}/#{repo['name']}"

        clone repo unless File.exists?(repo['repo_path'])
        get_forks repo if opts[:forks] and repo['forks'] > 1
        fetch_changes repo
        dump_issues repo if opts[:issues] && repo['has_issues']
        dump_wiki repo if opts[:wiki] && repo['has_wiki']
        
        logger.info "[done] backup repository #{repo['full_name']}"
      end

      def clone(repo)
        # // TODO(hbt) ENHANCE git clone recursive with submodules init?
        logger.debug "clone #{repo['ssh_url']}"
        puts cmd "git clone #{repo['ssh_url']}"
      end

      def fetch_changes(repo)
        logger.info "fetch all remotes"
        Dir.chdir(repo['repo_path'])
        # // TODO(hbt) ENHANCE use git fetch --all to include forks remotes -- also includes submodules
        # // TODO(hbt) ENHANCE fix hanging
        cmd "git fetch --all"
      end

      def get_forks(repo)
        Dir.chdir(repo['repo_path'])
        logger.info "fetch all forks"

        # // TODO(hbt) ENHANCE retrieve all forks including from the forked parent repo
        # do we get all forks
        (1..100).each do |i|
          # // TODO(hbt) ENHANCE review organization implementation. 
          if opts[:organization]
            url = "/repos/#{opts[:organization]}/#{repo['name']}/forks"
          else
            url = "/repos/#{opts[:username]}/#{repo['name']}/forks"
          end
          forks = json("#{url}?page=#{i}&per_page=100")
          logger.info "for each fork, add remotes"
          forks.each do |f|
            cmd "git remote add #{f['owner']['login']} #{f['ssh_url']} 2> /dev/null"
          end
          break if forks.size == 0
        end
      end

      def dump_issues(repo)
        Dir.chdir(repo['repo_path'])
        logger.info "dump issues"

        filename = repo['repo_path'] + "/issues_dump.txt"
        FileUtils.rm filename if File.exists?(filename)

        content = ''
        (1..100).each do |i|
          if opts[:organization]
            url = "/repos/#{opts[:organization]}/#{repo['name']}/issues"
          else
            url = "/repos/#{opts[:username]}/#{repo['name']}/issues"
          end
          issues = json("#{url}?page=#{i}&per_page=100")
          content += issues.join("")
          break if issues.size == 0
        end

        File.open(filename, 'w') { |f| f.write(content) }
      end

      def dump_wiki(repo)
        Dir.chdir(opts[:bakdir])
        logger.info "clone wiki"
        
        wiki_path = "#{opts[:bakdir]}/#{repo['name']}.wiki"
        %x{git clone git@github.com:#{repo['owner']['login']}/#{repo['name']}.wiki.git} unless File.exists?(wiki_path)
        if File.exists? wiki_path
          Dir.chdir(wiki_path)
          cmd "git fetch --all"
        end
      end

      def cmd(line)
        logger.debug "shell '#{line}'"
        system(line)
        logger.debug "[done] shell '#{line}'"
        logger.debug "#{$?}"
      end

      def json(url)
        # // TODO(hbt) ENHANCE inv using token
        # // TODO(hbt) ENHANCE review github api changes
        auth = {:username => opts[:username], :password => opts[:passwd]} if opts[:username] and opts[:passwd]
        url = 'https://api.github.com' << url
        logger.debug "Authentication data: #{auth}, API URL: #{url}"
        HTTParty.get(url, :basic_auth => auth, :headers => {"User-Agent" => "Get out of the way, Github"}).parsed_response
        # // TODO(hbt) ENHANCE add error message handling
      end
    end
  end
end