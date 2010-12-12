#!/usr/bin/env ruby

require 'rubygems'
require 'rack'
require 'hiki/app'

Rack::Handler::CGI.run(
  Rack::ShowExceptions.new(
  Rack::CommonLogger.new(
    Hiki::App.new('hikiconf.rb')
)))
