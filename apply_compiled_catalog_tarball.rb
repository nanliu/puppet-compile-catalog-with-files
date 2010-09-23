#!/usr/bin/ruby
require 'getoptlong'
opts = GetoptLong.new(
  [ '--node', '-n', GetoptLong::REQUIRED_ARGUMENT ]
)

node = nil
opts.each do |opt, arg|
  case opt
    when '--node'
      node = arg
  end
end

