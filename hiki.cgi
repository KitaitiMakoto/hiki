#!/usr/bin/env ruby

require 'rubygems'
require 'rack'
require 'hiki/app'
require 'hiki/attachment'

Rack::Handler::CGI.run(
  Rack::Lint.new(
  Rack::ShowExceptions.new(
  Rack::CommonLogger.new(
  Rack::URLMap.new(
    '/attach' => Hiki::Attachment.new('hikiconf.rb'),
    '/' => Hiki::App.new('hikiconf.rb')
)))))
