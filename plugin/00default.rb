# $Id: 00default.rb,v 1.17 2005-01-28 12:29:04 fdiary Exp $
# Copyright (C) 2002-2003 TAKEUCHI Hitoshi <hitoshi@namaraii.com>

#==============================
#  tDiary plugins for Hiki
#==============================
def anchor( s )
  s.sub!(/^\d+$/, '')
  p = @page.escape.escapeHTML
  p.gsub!(/%/, '%%')
  %Q[?#{p}#{s}]
end

def my( a, str )
  %Q[<a href="#{anchor(a).gsub!(/%%/, '%')}">#{str.escapeHTML}</a>]
end

#==============================
#  Hiki default plugins
#==============================
#===== hiki_url
def hiki_url(page)
  "#{@conf.cgi_name}?#{page.escape}"
end

#===== hiki_anchor
def hiki_anchor( page, display_text )
  unless page == 'FrontPage' then
    make_anchor("#{@conf.cgi_name}?#{page}", display_text)
  else  
    make_anchor(@conf.cgi_name, display_text)
  end
end

#===== make_anchor
def make_anchor(url, display_text)
  %Q!<a href="#{url}">#{display_text}</a>!
end

#===== page_name
def page_name( page )
  pg_title = @db.get_attribute(page, :title)
  ((pg_title && pg_title.size > 0) ? pg_title : page).escapeHTML
end

#===== toc
def toc
  @toc_f = true
end

#===== recent
def recent( n = 20 )
  n = n > 0 ? n : 0

  l = @db.page_info.sort do |a, b|
    b[b.keys[0]][:last_modified] <=> a[a.keys[0]][:last_modified]
  end

  s = ''
  c = 0
  ddd = nil
  
  l.each do |a|
    break if (c += 1) > n
    name = a.keys[0]
    p = a[name]
    
    tm = p[:last_modified ] 
    cur_date = tm.strftime( @conf.msg_date_format )

    if ddd != cur_date
      s << "</ul>\n" if ddd
      s << "<h5>#{cur_date}</h5>\n<ul>\n"
      ddd = cur_date
    end
    t = page_name(name)
    an = hiki_anchor(name.escape, t)
    s << "<li>#{an}\n"
  end
  s << "</ul>\n"
  s
end

#===== update_proc
add_update_proc {
  updating_mail if @conf.mail_on_update
  @conf.repos.commit(@page)
}

#----- send a mail on updating
def updating_mail
  begin
    latest_text = @db.load(@page) || ''
    type = (!@db.text or @db.text.size == 0) ? 'create' : 'update'
    text = ''
    text  = "#{@db.text}\n#{'-' * 25}\n" if type == 'update'
    text << "#{latest_text}\n"

    send_updating_mail(@page, type, text)
  rescue
  end
end

#===== delete_proc
add_delete_proc {
  @conf.repos.delete(@page)
}

#===== hiki_header
add_header_proc {
  hiki_header
}

def hiki_header
  s = <<EOS
  <meta http-equiv="Content-Language" content="#{@conf.lang}">
  <meta http-equiv="Content-Type" content="text/html; charset=#{@conf.charset}">
  <meta http-equiv="Content-Script-Type" content="text/javascript; charset=euc-jp">
  <meta http-equiv="Content-Style-Type" content="text/css">
  <meta name="generator" content="#{@conf.generator}">
  <title>#{title}</title>
  <link rel="stylesheet" type="text/css" href="#{base_css_url.escapeHTML}" media="all">
  <link rel="stylesheet" type="text/css" href="#{theme_url.escapeHTML}" media="all">
EOS
  s << <<EOS if @command != 'view'
  <meta name="ROBOTS" content="NOINDEX,NOFOLLOW"> 
  <meta http-equiv="pragma" content="no-cache">
  <meta http-equiv="cache-control" content="no-cache">
  <meta http-equiv="expires" content="0">
EOS
  s
end

#===== hiki_footer
add_footer_proc {
  hiki_footer
}

def hiki_footer
  <<EOS
Generated by <a href="http://www.namaraii.com/hiki/">Hiki</a> #{HIKI_VERSION}.<br>
Powered by <a href="http://www.ruby-lang.org/">Ruby</a> #{RUBY_VERSION}#{if /ruby/i =~ ENV['GATEWAY_INTERFACE'] then ' with <a href="http://www.modruby.net/">mod_ruby</a>' end}.<br>
Founded by #{@conf.author_name.escapeHTML}.<br>
EOS
end

#===== edit_proc
add_edit_proc {
  hiki_anchor(@page.escape, "[#{page_name(@page)}]")
}

#===== menu
def hiki_menu(data, command)
  menu = []
  editable = %w(view edit diff)

  if @conf.bot?
    menu << %Q!<a accesskey="i" href="#{@conf.cgi_name}?c=index">#{@conf.msg_index}</a>!
  else
    menu << %Q!<a accesskey="c" href="#{@conf.cgi_name}?c=create">#{@conf.msg_create}</a>!
    menu << %Q!<a accesskey="e" href="#{@conf.cgi_name}?c=edit;p=#{@page.escape}">#{@conf.msg_edit}</a>! if editable.index(command) && @page
    menu << %Q!<a accesskey="d" href="#{@conf.cgi_name}?c=diff;p=#{@page.escape}">#{@conf.msg_diff}</a>! if editable.index(command) && @page
    menu << %Q!#{hiki_anchor( 'FrontPage', page_name('FrontPage') )}!
    menu << %Q!<a accesskey="i" href="#{@conf.cgi_name}?c=index">#{@conf.msg_index}</a>!
    menu << %Q!<a accesskey="s" href="#{@conf.cgi_name}?c=search">#{@conf.msg_search}</a>!
    menu << %Q!<a accesskey="r" href="#{@conf.cgi_name}?c=recent">#{@conf.msg_recent_changes}</a>!
    @plugin_menu.each do |c|
      next if c[:option].has_key?('p') && !editable.index(command)
      cmd =  %Q!<a href="#{@conf.cgi_name}?c=#{c[:command]}!
      c[:option].each do |key, value|
        value = @page.escape if key == 'p'
        cmd << %Q!;#{key}=#{value}!
      end
      cmd << %Q!">#{c[:display_text]}</a>!
      menu << cmd
    end
    menu_proc.each {|i| menu << i}
    menu << %Q!<a accesskey="m" href="#{@conf.cgi_name}?c=admin">#{@conf.msg_admin}</a>!
  end

  data[:tools] = menu.collect! {|i| %Q!<span class="adminmenu">#{i}</span>! }.join("&nbsp;\n").sanitize
end

# conf: default
def saveconf_default
  if @mode == 'saveconf' then
    @conf.site_name = @cgi.params['site_name'][0]
    @conf.author_name = @cgi.params['author_name'][0]
    @conf.mail = @cgi.params['mail'][0]
    @conf.mail_on_update = @cgi.params['mail_on_update'][0] == "true"
  end
end

# conf: password
def saveconf_password
  if @mode == 'saveconf' then
    old_password    = @cgi.params['old_password'][0]
    password1       = @cgi.params['password1'][0]
    password2       = @cgi.params['password2'][0]
    if password1.size > 0
      if (@conf.password.size > 0 && old_password.crypt( @conf.password ) != @conf.password) ||
	  (password1 != password2)
	admin_config( nil, @conf.msg_invalid_password )
	return
      end
      salt = [rand(64),rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
      @conf.password = password1.crypt( salt )
    end
  end
end

# conf: display
def saveconf_theme
  # dummy
end

if @cgi.params['conf'][0] == 'theme' && @mode == 'saveconf'
  @conf.theme          = @cgi.params['theme'][0]
  @conf.use_sidebar    = @cgi.params['sidebar'][0] == "true"
  @conf.main_class     = @cgi.params['main_class'][0]
  @conf.main_class     = 'main' if @conf.main_class == ''
  @conf.sidebar_class  = @cgi.params['sidebar_class'][0]
  @conf.sidebar_class  = 'sidebar' if @conf.sidebar_class == ''
  @conf.auto_link      = @cgi.params['auto_link'][0] == "true"
  @conf.theme_url      = @cgi.params['theme_url'][0]
  @conf.theme_path     = @cgi.params['theme_path'][0]
end

if @cgi.params['conf'][0] == 'theme'
  @conf_theme_list = []
  Dir::glob( "#{@conf.theme_path}/*".untaint ).sort.each do |dir|
    theme = dir.sub( %r[.*/theme/], '')
    next unless FileTest::file?( "#{dir}/#{theme}.css".untaint )
    name = theme.split( /_/ ).collect{|s| s.capitalize}.join( ' ' )
    @conf_theme_list << [theme,name]
  end
end
