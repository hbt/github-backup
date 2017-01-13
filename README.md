# github-backup

// TODO(hbt) ENHANCE update description
Command-line tool to backup data from github


// TODO(hbt) ENHANCE review list of stuff copied
## Copies 

* user and organization repositories (with submodules)
* forks (whole network)
* issues (into a JSON file per repository)
* wiki (cloned)
* gists (cloned)
* starred gists (cloned)


## Installation

```
# git version 1.9.1
git --version

# compatible with latest versions but if you run into issues. This is the official version
rvm use ruby-1.9.3-p547
ruby -v

# compatible with latest bundle but this is the official 
gem install bundle:1.0.0
bundle -v 

git clone git@github.com:hbt/github-backup.git
cd github-backup
bundle

./bin/github-backup -h

```


// TODO(hbt) ENHANCE update usage
## Usage

```
Usage: github-backup -u [username] -o [dir]
e.g
github-backup -u hbt -o /tmp 

    -u, --username USERNAME          *Required: GitHub username
    -o, --output-dir DIR             *Required: Backup directory
    -p, --password PASSWORD          Optional: GitHub password. Required for private repos
    -O ORGANIZATION_NAME,            Optional: Organization name of the organization to fetch repositories from
        --organization
    -r, --repository-name NAME       Optional: limit to this repository name
    -f, --forks                      Optional: fetch all forks
    -i, --dump-issues                Optional: dump all issues
    -w, --wiki                       Optional: dump wiki
    -D, --debug                      Optional: enable logging debug messages
    -v, --version                    Displays current version 
    -h, --help                       Displays this screen

```

// TODO(hbt) ENHANCE add examples of usage + explanations

## Copyright

Copyright (c) 2012 hbt. See LICENSE.txt for
further details.

