#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'

ours = YAML.load_file(ARGV[1])["updated_at"]
theirs = YAML.load_file(ARGV[2])["updated_at"]

if ours < theirs
  FileUtils.cp(ARGV[2], ARGV[1])
end
exit 0
