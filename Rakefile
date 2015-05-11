require 'pathname'
require 'shellwords'

class Pathname
	def shellescape
		to_s.shellescape
	end
end

namespace :nginx do
	task build: %w[tmp] do |t,conf|
		sh './nginx.build'
	end

	def call_nginx *opts
		base_dir = Pathname.new( '.').expand_path
		binary = base_dir.join *%w[nginx sbin nginx]
		config = base_dir.join *%w[config nginx.conf]
		sh "sudo #{binary.shellescape} -c #{config.shellescape} #{opts.map(&:to_s).shelljoin}"
	end

	task :start do |t,conf|
		call_nginx
	end

	task :stop do |t,conf|
		call_nginx '-s', :quit
	end

	task :reload do |t,conf|
		call_nginx '-s', :reload
	end
end

task :mime_types_json do |t,conf|
	sh './scripts/mimetype-mapper.json.rb config/mime.types html/icons/mimetypes > html/mime-types.json'
end

directory 'store'
directory 'tmp'

task build: %w[nginx:build mime_types_json store]
