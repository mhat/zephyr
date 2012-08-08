# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "zephyr"
  gem.homepage = "http://github.com/mhat/zephyr"
  gem.license = "MIT"
  gem.summary = %Q{Battle-tested HTTP client using Typhoeus, derived from the Riak client}
  gem.description = %Q{Battle-tested HTTP client using Typhoeus, derived from the Riak client}
  gem.email = "matt.knopp@gmail.com"
  gem.authors = ["Matt Knopp"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

##require 'rcov/rcovtask'
##Rcov::RcovTask.new do |test|
##  test.libs << 'test'
##  test.pattern = 'test/**/test_*.rb'
##  test.verbose = true
##  test.rcov_opts << '--exclude "gems/*"'
##end

task :default => :test

