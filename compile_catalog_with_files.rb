#!/usr/bin/ruby
#
# Copyright PuppetLabs 2010

require 'trollop'
require 'puppet'
require 'pp'

opts = Trollop::options {
  version 'compile_catalog_with_files.rb beta (c) 2010 Puppet Labs'
  banner <<-EOS
Usage:
  compile_catalog_with_files.rb

Options:
EOS
  opt :node, 'node name',
      :short => '-n',
      :type => :string
  opt :confdir, 'puppet $confdir',
      :short => '-c',
      :type => :string
  opt :vardir, 'puppet $vardir',
      :short => '-v'
  opt :modulepath, 'puppet modulepath',
      :short => '-p',
      :type => :string
  opt :external_nodes, 'external_nodes script',
      :short => '-e',
      :type => :string
  opt :manifest, 'puppet site.pp manifest',
      :short => '-m',
      :type => :string
  opt :verbose, 'enable debug mode',
      :default => false
}

Trollop::die :node, "must specify node." unless opts[:node]
# Reload :confdir
Puppet[:confdir] = opts[:confdir] if opts[:confdir]
Puppet.settings.parse

# Puppet obtains facts from yaml
Puppet::Node::Facts.terminus_class = :yaml

node = opts[:node]
Puppet[:modulepath] = opts[:modulepath] if opts[:modulepath]
Puppet[:vardir] = opts[:vardir] if opts[:vardir]

if opts[:external_nodes]
  # use the external nodes tool - should read from puppet's puppet.conf
  # but doesn't read from the master section because run_mode can't be set.  ticket #4790
  Puppet[:node_terminus] = :exec
  Puppet[:external_nodes] = opts[:external_nodes]
end

#Puppet::Node::Facts.terminus_class = :yaml

# we're running this on the server but Puppet.run_mode doesn't know that in this script
# so it ends up using clientyamldir
Puppet[:clientyamldir] = Puppet[:yamldir]

begin
  unless compiled_catalog = Puppet::Resource::Catalog.find(node)
    raise "Could not compile catalog for #{node}"
  end
  compiled_catalog_pson_string = compiled_catalog.to_pson

  paths = compiled_catalog.vertices.
      select {|vertex| vertex.type == "File" and vertex[:source] =~ %r{puppet://}}.
      map {|file_resource| Puppet::FileServing::Metadata.find(file_resource[:source])}. # this step should return nil where source doesn't exist
      compact.
      map {|filemetadata| filemetadata.path}

rescue => detail
  $stderr.puts detail
  exit(30)
end

pp paths if opts[:verbose]
pp compiled_catalog_pson_string if opts[:verbose]

catalog_file = File.new("#{node}.catalog.pson", "w")
catalog_file.write compiled_catalog_pson_string
catalog_file.close

File.open("#{node}.modulepath", 'w') {|f| f.write(Puppet[:modulepath])}

tarred_filename = "#{node}.compiled_catalog_with_files.tar.gz"
puts "Created #{tarred_filename} with the compiled catalog for node #{node} and the necessary files" if opts[:verbose]
`tar -cPzf #{tarred_filename} #{catalog_file.path} #{node}.modulepath #{paths.join(' ')}`
pp Puppet if opts[:verbose]
File.delete(catalog_file.path)
File.delete("#{node}.modulepath")
