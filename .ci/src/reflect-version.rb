#!/usr/bin/env ruby

require 'fileutils'
require 'tempfile'
require 'yaml'

version = ARGV.shift

Gem::Version.new(version).prerelease? and raise "prerelease is not allowed"

begin
  raise 'Please check your current working directory. ./bitrise.yml is unavailable.' unless File.exist?('bitrise.yml')

  bitrise_yml = YAML.safe_load(File.read('bitrise.yml'))

  new_envs = bitrise_yml['app']['envs'].dup
  new_envs.delete_if { |env| env.key?('BITRISE_STEP_VERSION') }
  new_envs << { "BITRISE_STEP_VERSION" => version }

  bitrise_yml['app']['envs'] = new_envs

  File.open('bitrise.yml', 'w') do |f|
    f.write(bitrise_yml.to_yaml)
  end
end

begin
  Tempfile.open('step.sh') do |dest|
    File.open('step.sh', 'r') do |src|
      src.each_line do |line|
        if line.include?('id=step-version')
          dest << "readonly STEP_VERSION=#{version} # id=step-version : Do not modify this line manually.\n"
        else
          dest << line
        end
      end
    end
    
    FileUtils.mv(dest.path, 'step.sh')
  end
end