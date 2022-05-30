#!/usr/bin/env ruby

input_path = ARGV.shift
output_path = ARGV.shift

File.open(output_path, "w") do |dest|
  File.open(input_path, 'r') do |src|
    do_extract = false

    f.each_line do |line|
      do_extract = line == '<evaluated-template>' unless do_extract

      next unless do_extract
      break if line.include?('</evaluated-template>')
    
      dest << line
    end
  end
end
