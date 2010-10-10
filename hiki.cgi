#!/usr/bin/env ruby

begin

require 'rubygems'
require 'rack'
require 'hiki/app'
require 'hiki/attachment'

Rack::Handler::CGI.run(
  Rack::URLMap.new(
    '/attach' => Hiki::Attachment.new('hikiconf.rb'),
    '/' => Hiki::App.new('hikiconf.rb')
))

rescue => evar

print "Content-Type: text/html\n\n"
puts '<pre>'
puts "#{evar.class}: #{evar.message}"
puts evar.backtrace
puts '</pre>'

end
