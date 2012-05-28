module Hiki
  class Config
    module Flatfile
      def cgi_conf
        @cgi_conf_flatfile ||= File.open( @config_file ){|f| f.read }.to_s
      end

      def save_config
        conf = ERB.new( File.open( "#{@template_path}/hiki.conf" ){|f| f.read }.untaint ).result( binding )
        File.open(@config_file, "w") do |f|
          f.print conf
        end
      end
    end

    include Flatfile
  end
end
