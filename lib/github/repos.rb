require 'fileutils'

module GitHubBackup
    module GitHub
        class << self
            attr_accessor :opts
            def options=(v)
                self.opts = v
            end

            def backup_repos()
                # get all repos
                (1..100).each do |i|
                    repos = json("/users/#{opts[:username]}/repos?page=#{i}per_page=100")
                    repos.each do |f|
                        # do we limit to a specific repo?
                        next unless f['name'] == opts[:reponame] if opts[:reponame]
                        backup_repo f
                    end
                    break if repos.size == 0
                end

            end

            def backup_repo(repo)
                Dir.chdir(opts[:bakdir])
                repo_path = "#{opts[:bakdir]}/#{repo['name']}"
                # clone
                %x{git clone #{repo['ssh_url']}} unless File.exists?(repo_path)
                Dir.chdir(repo_path)

                # run pull
                %x{git fetch origin}

                # do we get all forks
                if opts[:forks] and repo['forks'] > 1
                    (1..100).each do |i|
                        forks = json("/repos/#{opts[:username]}/#{repo['name']}/forks?page=#{i}&per_page=100")
                        forks.each do |f|
                            %x{git remote add #{f['owner']['login']} #{f['git_url']}}
                            %x{git fetch #{f['owner']['login']}}
                        
                        end
                        break if forks.size == 0
                    end
                end

                %x{for remote in `git branch -r `; do git branch --track $remote; done} if opts[:init_branches]

                repo['repo_path'] = repo_path
                dump_issues repo if opts[:issues] && repo['has_issues']
                dump_wiki repo if opts[:wiki] && repo['has_wiki']
            end

            def dump_issues(repo)
                Dir.chdir(repo['repo_path'])

                filename = repo['repo_path'] + "/issues_dump.txt"
                FileUtils.rm  filename if File.exists?(filename)

                content = ''
                (1..100).each do |i|
                    issues = json("/repos/#{opts[:username]}/#{repo['name']}/issues?page=#{i}&per_page=100")
                    content += issues.join("")
                    break if issues.size == 0
                end

                File.open(filename, 'w') {|f| f.write(content)}
            end

            def dump_wiki(repo)
                Dir.chdir(opts[:bakdir])
                wiki_path = "#{opts[:bakdir]}/#{repo['name']}.wiki"
                %x{git clone git@github.com:#{repo['owner']['login']}/#{repo['name']}.wiki.git} unless File.exists?(wiki_path)
                if File.exists? wiki_path
                    Dir.chdir(wiki_path)
                    %x{git fetch origin}
                end
            end

            def json(url)
                auth = {:username => opts[:email], :password => opts[:passwd]} if opts[:email] and opts[:passwd]
                HTTParty.get('https://api.github.com' << url, :basic_auth => auth).parsed_response
            end
        end
    end
end