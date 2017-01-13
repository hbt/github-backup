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
            next if f['fork'] == true if opts[:skip_forked]
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
        get_forks repo if opts[:forks] and (repo['forks_count'] > 0 || repo['fork'] == true)
        fetch_changes repo
        dump_issues repo if opts[:issues] && repo['has_issues']
        dump_wiki repo if opts[:wiki] && repo['has_wiki']

        logger.info "[done] backup repository #{repo['full_name']}"
      end

      def clone(repo)
        logger.debug "clone #{repo['ssh_url']}"
        puts cmd "git clone --recursive #{repo['ssh_url']}"
      end

      def fetch_changes(repo)
        logger.info "fetch all remotes"
        Dir.chdir(repo['repo_path'])
        cmd "git fetch --all --recurse-submodules=yes"
      end

      def get_all_forks(source_repo_full_name)
        ret = []
        (1..100).each do |i|
          url = ("/repos/#{source_repo_full_name}/forks")
          forks = json("#{url}?page=#{i}&per_page=100")
          
          forks.each do |f|
            ret.push(f['full_name'])
            if(f['forks_count'] > 0)
              ret.push(*get_all_forks(f['full_name']))
            end
          end
          break if forks.size == 0
        end

        ret
      end

      def get_forks(repo)
        Dir.chdir(repo['repo_path'])
        logger.info "fetch all forks"

        # source repo is different from parent. parent is direct parent of fork, source is the grand parent of all
        repo = json("/repos/#{repo['full_name']}")
        source_repo = (repo['fork'] == true && json("/repos/#{repo['source']['full_name']}")) || repo
        logger.debug "retrieving forks from source #{source_repo['full_name']}"
        
        logger.info "fetching forks network"
        forks = get_all_forks(source_repo['full_name'])
        logger.debug "NB forks vs source_repo forks count: #{forks.size} vs #{source_repo['forks_count']}"

        logger.info "for each fork, add remotes"
        forks.each do |f|
            user,repo = f.split "/"
            sshurl = "git@github.com:#{user}/#{repo}.git"
            cmd "git remote add #{user} #{sshurl} 2> /dev/null"
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
        auth = {:username => opts[:username], :password => opts[:passwd]} if opts[:username] and opts[:passwd]
        url = 'https://api.github.com' << url
        logger.debug "Authentication data: #{auth}, API URL: #{url}"
        ret = HTTParty.get(url, :basic_auth => auth, :headers => {"User-Agent" => "Get out of the way, Github"}).parsed_response
        if ret.is_a?(Hash) && ret.has_key?('message')
          logger.error "invalid API call - #{url} - #{ret['message']}"
          abort("invalid API call")
        end
        ret
      end
    end
  end
end