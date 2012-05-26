require 'hiki/db/tmarshal'
require 'sequel'

module Hiki
  class Config
    module RDBMS
      def cgi_conf
        unless @cgi_conf_rdbms
          Sequel.connect(@rdbms_setting) do |db|
            @cgi_conf_rdbms = db[:metadata].filter(:key => 'config').select_map(:value).first.to_s
          end
        end
        @cgi_conf_rdbms
      end

      def save_config
        conf = ERB.new( File.open( "#{@template_path}/hiki.conf" ){|f| f.read }.untaint ).result( binding )
        Sequel.connect(@rdbms_setting) do |db|
          db[:metadata].filter(:key => 'config').update(:value => conf)
        end
      end
    end

    include RDBMS
  end
end
