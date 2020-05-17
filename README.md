# README

## Installation

```bash
bundle

yarn install

rails db:setup

rails c
```
```ruby
Notebook.create(name: "journal") # default notebook

Notebook.create(name: "work")
CalendarHandler.new("work", "http://example.com/path-to.ics"); ch.process!
exit
```
```bash
rails s

# or

forego start
```

visit http://localhost:3000/work/timeline

## Backup

```
rails runner 'Exporter.new("/your/path/here").export!'
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
echo "HOSTNAME=yourlocalhostname" >> .env.development
```
