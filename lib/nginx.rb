
require 'shellwords'
require 'uri'
require 'pathname'

class Pathname
	def chdir &block
		Dir.chdir self.to_s, &block
	end
end

class NginxBuilder
	class ShellFailed < Exception
		def initialize a, re
			super "(#{re}) Command failed: #{a.shelljoin}"
		end
	end

	attr_reader :modules, :source_uri, :source_dir, :opts
	alias source source_dir

	def self.new *args, &block
		nginx = super *args
		if block_given?
			yield nginx
			nginx.configure
			nginx.compile
			nginx.install
		else
			nginx
		end
	end

	def initialize source, opts = nil
		opts = opts.is_a?( Hash) ? opts.dup : {}
		self.base_dir = opts[:base_dir]  if opts[:base_dir]
		self.tmp_dir = opts[:tmp_dir]  if opts[:tmp_dir]
		@source_uri = URI.parse source.to_s
		@source_dir = fetch @source_uri
		@modules, @opts = [], []
	end

	def shell *a
		a = a.flatten.map &:to_s
		puts "\e[34;1mrun: #{a.shelljoin}\e[0m"
		raise ShellFailed.new( a, $?)  unless Kernel.system( *a)
	end

	def work_dir dir
		dir = Pathname.new dir.to_s  unless dir.is_a? Pathname
		dir = tmp_dir + dir.to_s  unless dir.absolute?
		dir
	end

	def fetch_git uri, c = nil, dir = nil
		dir = work_dir dir || File.basename( uri.to_s, '.git')
		unless File.directory? dir
			clone_uri = uri.clone
			clone_uri.scheme = 'https'
			dir.dirname.chdir { shell :git, :clone, clone_uri }
		else
			dir.chdir { shell :git, :pull }
		end
		dir.chdir { shell :git, :checkout, c }  if c
		dir
	end

	def fetch_http uri, dir = nil
		tar = File.basename( uri.to_s)
		dir = work_dir dir || tar.to_s.gsub( /\.(tar|tbz2|txz|tgz)(.*)?$/, '')
		dir.dirname.chdir do
			shell :wget, '-c', uri
			shell :tar, :xf, tar
		end
		dir
	end
	alias fetch_https fetch_http

	def fetch uri, *args
		uri = URI.parse uri.to_s
		puts "\e[36;1mfetch (#{uri.scheme}) #{uri}\e[0m"
		dir = send "fetch_#{uri.scheme}", uri, *args
		Pathname.new( dir.to_s).expand_path
	end

	def module( *args) @modules.push fetch( *args) end
	def configure_add_module() @modules.map {|m| "--add-module=#{m}" } end
	def configure( *opts) source.chdir { shell './configure', configure_add_module, @opts, opts } end

	def opt name, arg = nil
		opt = "--#{name}"
		opt += "=#{arg}"  if arg
		@opts.push opt
	end

	def with( name, arg = nil) opt "with-#{name}", arg end
	def without( name, arg = nil) opt "without-#{name}", arg end
	def enable( name, arg = nil) opt "enable-#{name}", arg end
	def disable( name, arg = nil) opt "disable-#{name}", arg end

	def compile() source.chdir { shell :make } end
	def install() source.chdir { shell :make, :install } end

	def base_dir=( bd) @base_dir = Pathname.new( bd.to_s).expand_path end
	def base_dir() @base_dir ||= Pathname.new( '.').expand_path end
	def tmp_dir=( bd) @tmp_dir = Pathname.new( bd.to_s).expand_path end
	def tmp_dir() @tmp_dir || base_dir+'tmp' end
end
