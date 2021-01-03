#!/usr/bin/env ruby
# This script is used as a custom git merge driver for handling merge conflicts.
# Expected input are: %O %A %B, aka ancestor, our version, their version.
require 'yaml'
require 'fileutils'

ours = YAML.load_file(ARGV[1])["updated_at"]
theirs = YAML.load_file(ARGV[2])["updated_at"]

if ours < theirs
  FileUtils.cp(ARGV[2], ARGV[1])
end
exit 0
