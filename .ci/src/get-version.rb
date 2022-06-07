#!/usr/bin/env ruby

require 'yaml'

raise 'Please check your current working directory. ./bitrise.yml is unavailable.' unless File.exist?('bitrise.yml')

bitrise_yml = YAML.safe_load(File.read('bitrise.yml'))
puts bitrise_yml['app']['envs'].find { |env| env.key?('BITRISE_STEP_VERSION') }['BITRISE_STEP_VERSION']
