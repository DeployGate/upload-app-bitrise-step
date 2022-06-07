#!/usr/bin/env ruby

require 'erb'

current_version = ARGV.shift
new_version = ARGV.shift

head_branch = `git branch --show-current`.chomp
pr_nums = `.ci/get-merged-pr-numbers --baseline-tag #{current_version} --head-branch #{head_branch}`.chomp.split("\n")

puts ERB.new(File.read('.ci/templates/release_pr_body.md')).result(binding)
