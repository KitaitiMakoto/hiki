#!/usr/bin/env rackup
# -*- ruby -*-
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'hiki/app'
require 'hiki/attachment'

use Rack::Lint
use Rack::ShowExceptions
use Rack::Reloader
use Rack::Session::Cookie, :secret => 'fjiS(jewa899ew89', :expire_after => 60 * 60, :key => 'hiki.session'
#use Rack::ShowStatus
use Rack::CommonLogger
use Rack::Static, :urls => ['/theme'], :root => '.'

map '/' do
  run Hiki::App.new('hikiconf.rb')
end
map '/attach' do
  run Hiki::Attachment.new('hikiconf.rb')
end
