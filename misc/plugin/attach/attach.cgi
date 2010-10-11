#!/usr/bin/env ruby

require 'rubygems'
require 'rack'
require 'hiki/attachment'

Rack::Handler::CGI.run(
  Rack::Lint.new(
  Rack::ShowExceptions.new(
  Rack::CommonLogger.new(
  Rack::URLMap.new(
    '/' => Hiki::Attachment.new('hikiconf.rb')
)))))
