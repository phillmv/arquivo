# Hello

This is the source code repository for Arquivo, a note-taking app.

## Vision

Arquivo seeks to be an archive for your digital artifacts, ephemera, and notes. Its purpose is to help you keep track of your research, tasks, and thoughts, and help you produce better end products (i.e. essays, papers, books, apps).

I currently use this app for daily journaling, keeping track of household information, and all of the notekeeping required to perform my day job as a software engineer.

## Values

Arquivo's design choices and compromises are driven by the following values:

1. **Trust**. You control where your data lives, and who can access it.
2. **Durability**. Your data is portable by default, and it should outlive this app.
3. **Longevity**. You should be able to keep using this app for at least 10+ years.

## Goals

Arquivo will be a successful project if:

- It can store and search all the digital artifacts I care about.
- Different users can successfully use their own organization strategies.
- Using this app actually leads to better end products (i.e. essays, papers, books, apps).

## Features

Arquivo currently supports the following features:

- write notes in markdown
- attach files to notes
- create tasks from notes
- organize notes by notebook
- notebooks are automatically serialized to files and folders
- serialized files are stored in git repos
- fulltext search
- search by hashtag or @-mention
- bookmark websites
- sync calendars via `.ical` files
- sync with pinboard


## Installation

At the time of writing, very little effort has gone into making the app comfortable for new users. These instructions may be out of date.

I hereby assume you, dear reader, have a certain level of familiarity with ruby, rails, and node.


```bash
git clone git@github.com:phillmv/arquivo.git

bundle

yarn install

rails db:setup

rails c
```

The app assumes you have a `$HOME/Documents` folder, and will try to create a `$HOME/Documents/arquivo` subdirectory.

Right now, there is no interface for creating notebooks aside from the console. The app assumes there's a Notebook called "journal", and you will want to create a few more at your leisure.

```ruby
Notebook.create(name: "journal") # default notebook

Notebook.create(name: "work")
```

### Adding a calendar

```ruby
CalendarImport.create(notebook: "your-notebook-here",
                      title: "name-of-calendar",
                      url: "http://example.com/path-to.ics");

# to manually process it:
UpdateCalendarsJob.perform_now!

```

### Let's go!

Then just start the server:

```bash
rails s

# or

forego start
```

visit http://localhost:3000/work/timeline

I _highly_ recommend setting a local hostname of `arquivo.localhost` for your app. Some minor features may not work out of the box otherwise.

## Import / Export

Meant to sync notebooks between machines. This works quite well with Dropbox.

```bash
rails runner 'SyncToDisk.export_all!("/your/path/here/arquivo")'
rails runner 'SyncFromDisk.import_all!("/your/path/here/arquivo")'
```

## Developing

You can install Ruby, Node etc locally OR

you can use the provided `nix-shell` configuration.

### Using nix-shell for development

* install the nix package manager https://nixos.org/download.html - if you are on MacOS Catalina see https://gist.github.com/ghedamat/25c671a02923dbac6c140afe54276f9e
* type `nix-shell` in the root of this project
* you are now in a `bash` shell that has all the required dependencies, type `bundle` and you'll be good to go

### Customizing the hostname

```
echo "HOSTNAME=arquivo.localhost" >> .env.development
```
