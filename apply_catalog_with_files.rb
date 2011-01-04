#!/usr/bin/ruby
#
# Copyright PuppetLabs 2010

require 'trollop'
require 'pp'

apply_opts = ""
# obtain list of options to pass to puppet apply
i = ARGV.index('-o') || ARGV.index('--options')
if i
  apply_opts = ARGV[i+1]
  ARGV.delete_at(i+1)
end

opts = Trollop::options do
  version 'apply_catalog_with_files.rb beta (c) 2010 Puppet Labs'
  banner <<-EOS
Usage:
  apply_catalog_with_files [-r] [-x extractdir] [-o passthroughoptions] -n nodefile

Options:
    --option, -o '<s>' :  List of options to pass to puppet apply
EOS

  opt :extractdir, 'Extract target directory for tar.gz',
      :short => '-x',
      :default => '/tmp'
  opt :nodefile, 'Node tar.gz file',
      :short => '-n',
      :type => :string
  opt :options, 'Options for puppet apply',
      :short => '-o',
  opt :report, 'Enable store report.',
      :short => '-r'
  opt :verbose, 'Enable debug mode.',
      :short => '-v'
end

dir = opts[:extractdir]
apply_opts += ' --report --reports=store' if opts[:report]

nodefile = opts[:nodefile]
nodefile =~ /(.*)\.compiled_catalog_with_files/
nodename = $1

puts "Extracting:\ntar -xf #{nodefile} -C #{dir}" if opts[:verbose]
Kernel.system("tar -xf #{nodefile} -C #{dir}")
pp "#{dir}/#{nodename}.modulepath"
modulepath = File.open("#{dir}/#{nodename}.modulepath").readlines.first
modulepath = modulepath.split(":").map {|path| dir + path}.join(":")

puts "Applying Catalog..." if opts[:verbose]
Kernel.system("puppet apply #{apply_opts} --apply #{dir}/#{nodename}.catalog.pson --modulepath #{modulepath}")

# Cleanup files
puts "Cleanup:" if opts[:verbose]
files = %x[tar -tf #{nodefile}].split("\n")
files.each do |f|
  puts "remove #{dir}/#{f}" if opts[:verbose]
  File.delete("#{dir}/#{f}")
end
