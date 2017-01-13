# github-backup

Command-line tool to backup data from github


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
    -F, --skip-forked                Optional: skip forked repositories.
    -i, --dump-issues                Optional: dump all issues into a file
    -w, --wiki                       Optional: clone repository wiki
    -D, --debug                      Optional: enable logging debug messages
    -v, --version                    Displays current version 
    -h, --help                       Displays this screen

```

## Examples

```
# retrieves all repositories and for each repo, its forks
github-backup -u hbt -p XXX --forks -o /tmp


# ignores any repositories I forked
github-backup -u hbt -p XXX --skip-forked -o /tmp

```

## Copyright

Copyright (c) 2012 hbt. See LICENSE.txt for
further details.

