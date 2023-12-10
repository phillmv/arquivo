# Hello

This is the source code repository for Arquivo, a note-taking app.

## Vision

Arquivo seeks to be an archive for your digital artifacts, ephemera, and notes. Its purpose is to help you keep track of your research, tasks, and thoughts, and help you produce better end products (i.e. essays, papers, books, apps).

I currently use this app for: daily journaling, personal bookmarking, keeping track of household projects, and all of the notekeeping required to perform my day job as a software engineer.

## Values

Arquivo's design choices and compromises are driven by the following values:

1. **Trust**. You control where your data lives, and who can access it.
2. **Durability**. Your data is portable by default, and it should outlive this app.
3. **Longevity**. You should be able to keep using this app for at least 10+ years.

Data is stored in markdown within a git repository. You will always be able to read your data, move it elsewhere, and revert back to an earlier version.

## Goals

Arquivo will be a successful project if:

- It can store and search all the digital artifacts I care about.
- Different users can successfully use their own organization strategies (bullet journaling, zettelkasten, whatever).
- Using this app actually leads to better end products (i.e. essays, papers, books, apps).

## Features

Arquivo currently supports the following features:

- write notes in markdown
- attach files to notes
- create tasks in notes
- organize notes by notebook
- notebooks are automatically serialized to files and folders
- serialized files are stored in git repos
- fulltext search
- search by hashtag or @-mention
- bookmark websites
- sync calendars via `.ical` files
- browse by week or month
- search todo lists
- generate a static website from your notebook


## Installation
### Mea culpa

Unfortunately, I've had no time to make anything easy to use. New users will have to drop into the Rails console and create a new Notebook, and then via the web interface add an ssh key for git syncing to work.

In the meantime, however, _advanced users_ are encouraged to poke thru the Dockerfile; development & deployment is intended to happen thru the corresponding container image.

### Getting started

Step 1: [Authenticate with the GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic).

Step 2: The following incantation should be sufficient to get a working dev environment off the ground:

```bash
# set up a local copy in, for example, ~/code/arquivo
git clone git@github.com:phillmv/arquivo.git ~/code

# set up a data folder in, for example, ~/Documents/arquivo
mkdir -p ~/Documents/arquivo

# boot up the server:
ARQUIVO_PORT=12346
export ARQUIVO_USER=your_user_here
export ARQUIVO_GIT_EMAIL=you@example.com
export ARQUIVO_GIT_NAME="Your Name"
export RAILS_ENV=development
export RAILS_MASTER_KEY=DUMMY
export RAILS_BIND=tcp://0.0.0.0:3001

docker run -it -p "$ARQUIVO_PORT":3001 \
  -e ARQUIVO_USER \
  -e ARQUIVO_GIT_EMAIL \
  -e ARQUIVO_GIT_NAME \
  -e RAILS_ENV \
  -e RAILS_MASTER_KEY \
  -e RAILS_BIND \
  -v ~/Documents/arquivo/:/data \
  -v ~/code/arquivo:/arquivo \
  ghcr.io/phillmv/arquivo-development:latest
```

This should bind a webserver to http://localhost:12346/ , and off you go. Consult this repository for the Dockerfile. A production image is published to `ghcr.io/phillmv/arquivo`.
