#!/usr/bin/env ruby

require 'rubygems'
require 'rack'
require 'hiki/app'
require 'hiki/attachment'

Rack::Handler::CGI.run(
  Rack::ShowExceptions.new(
  Rack::CommonLogger.new(
  Rack::URLMap.new(
    '/' => Hiki::App.new('hikiconf.rb')
))))
