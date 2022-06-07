#!/usr/bin/env ruby

input_path = ARGV.shift
output_path = ARGV.shift

File.open(output_path, "w") do |dest|
  File.open(input_path, 'r') do |src|
    do_extract = false

    src.each_line do |line|
      if !do_extract && line.include?('<evaluated-template>')
        do_extract = true
        next
      end

      next unless do_extract
      break if line.include?('</evaluated-template>')
    
      dest << line
    end
  end
end
