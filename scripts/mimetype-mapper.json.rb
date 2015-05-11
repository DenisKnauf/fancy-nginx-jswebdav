#!/usr/bin/env ruby
require 'json'
require 'pathname'

class KnorkeFancyExtMimeTypeIcons
	def initialize nginx_mime_types, icons_dir
		@nginx_mime_types, @icons_dir =
			Pathname.new( nginx_mime_types.to_s).expand_path, Pathname.new( icons_dir.to_s).expand_path
		@types, @icons = {}, {}
		@ret = {types: @types, icons: @icons}
	end

	def each_icon select = nil, &block
		to_enum :each_icon, select  unless block_given?
		case select
		when Regexp then true
		else select = %r<^#{Regexp.quote select.to_s.gsub( /\//, '-')}\.>
		end
		@icons_dir.to_enum( :each_child).lazy.
			select( &:file?).
			select {|x| select =~ x.basename.to_s }.
			each &block
	end

	def find_icon m
		each_icon( m).first || 
		each_icon( m.sub( /\/.*/, '/x-generic')).first ||
		each_icon( 'unknown').first ||
		raise( "icon for #{m} or unknown can not be found. (really, i searched for unknown, not for something unknown. it should be named unknown")
	end

	def build
		@nginx_mime_types.read.
			match( /types {([^}]*)}/)[1].
			split( ';').
			map {|x| x.split( /\s+/).grep(/./)}.
			reject {|(m,*es)| m.nil? || es.empty? }.
			map {|(m,*es)| [m, find_icon( m), *es] }.
			each {|(m,_,*es)| es.each {|e| @types[e] = m}}.
			each {|(m,i,*_)| @icons[m] = i.basename }
		self
	end

	def to_json() @ret.to_json end
end

puts KnorkeFancyExtMimeTypeIcons.new( *ARGV[0..1]).build.to_json
