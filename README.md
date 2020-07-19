# README

## Installation

```bash
bundle

yarn install

rails db:setup

rails c
```

App assumes there's a Notebook called "journal", and you will want to create a few more at your leisure.

```ruby
Notebook.create(name: "journal") # default notebook

Notebook.create(name: "work")
```

A notebook gets more useful once you add a calendar import:

```ruby
CalendarImport.create(notebook: "your-notebook-here",
                      title: "name-of-calendar",
                      url: "http://example.com/path-to.ics");

# to manually process it:
UpdateCalendarsJob.perform_now!

```

Then just start the server:

```bash
rails s

# or

forego start
```

visit http://localhost:3000/work/timeline

## Import / Export

Meant to sync notebooks between machines. This works quite well with Dropbox.

```bash
rails runner 'Exporter.new("/your/path/here").export!'
rails runner 'Importer.new("/your/path/here").import!'
```

# Developing

You can install Ruby, Node etc locally OR

you can use the provided `nix-shell` configuration.

## Using nix-shell for development

* install the nix package manager https://nixos.org/download.html - if you are on MacOS Catalina see https://gist.github.com/ghedamat/25c671a02923dbac6c140afe54276f9e
* type `nix-shell` in the root of this project
* you are now in a `bash` shell that has all the required dependencies, type `bundle` and you'll be good to go

## Customizing the hostname

```
echo "HOSTNAME=arquivo.localhost" >> .env.development
```
