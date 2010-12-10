# $Id: trackback.rb,v 1.14 2006-10-05 06:46:43 fdiary Exp $
# Copyright (C) 2004 Kazuhiko <kazuhiko@fdiary.net>

def trackback
  script_name = ENV['SCRIPT_FILENAME']
  base_url = script_name.nil? || script_name.empty? ? '' : File.basename(script_name)
  <<-EOF
<<<<<<< HEAD:misc/plugin/trackback.rb
<div class="caption">TrackBack URL: <a href="#{base_url}/tb/#{escape(@page)}">#{@conf.base_url}#{base_url}/tb/#{escape(@page)}</a></div>
=======
<div class="caption">TrackBack URL: <a href="#{File.basename(ENV['SCRIPT_FILENAME'])}/tb/#{escape(@page)}">#{@conf.base_url}#{File.basename(ENV['SCRIPT_FILENAME'])}/tb/#{escape(@page)}</a></div>
>>>>>>> 1463087... use Hiki::Util's utility methods instead of CGI's utility methods:misc/plugin/trackback.rb
EOF
end

def trackback_post
  params     = @request.params
  url = params['url']
  unless 'POST' == @request.request_method && url
    return redirect(@request, "#{@conf.index_url}?#{h(@page)}")
  end
  blog_name = ( params['blog_name'] || '' ).to_utf8
  title = ( params['title'] || '' ).to_utf8
  excerpt = ( params['excerpt'] || '' ).to_utf8

  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )

  flag = false
  content = ''
  lines.each do |l|
    if /^\{\{trackback\}\}/ =~ l && flag == false
      content << "#{l}\n"
      content << %Q!* trackback : #{@conf.parser.link( url, "#{title} (#{blog_name})" )} (#{format_date(Time.now)})\n!
      content << @conf.parser.blockquote( shorten( excerpt ) )
      flag = true
    else
      content << l
    end
  end

  save( @page, content, md5hex )

  response = <<-END
<?xml version="1.0" encoding="iso-8859-1"?>
<response>
<error>0</error>
</response>
END
  head = {
    'type' => 'text/xml',
    'Vary' => 'User-Agent'
  }
  head['Content-Length'] = response.size.to_s
  head['Pragma'] = 'no-cache'
  head['Cache-Control'] = 'no-cache'
  ::Hiki::Response.new(response, 200, head)
end
