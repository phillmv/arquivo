#!/usr/bin/env ruby
# This script is used as a custom git merge driver for handling merge conflicts.
# Expected input are: %O %A %B, aka ancestor, our version, their version.
require 'yaml'
require 'date'
require 'fileutils'

ours = YAML.load_file(ARGV[1], permitted_classes: [Symbol, Date, Time])["updated_at"]
theirs = YAML.load_file(ARGV[2], permitted_classes: [Symbol, Date, Time])["updated_at"]

if ours < theirs
  FileUtils.cp(ARGV[2], ARGV[1])
end
exit 0
