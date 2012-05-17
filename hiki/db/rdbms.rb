require 'hiki/config'
require 'hiki/storage'
require 'rubygems'
require 'sequel'

module Hiki
  # Not use file for cache and backup
  # because couldn't save file on Heroku when free plan
  # So store tokens(builded HTML and some infos) to cache table
  # and not use backup at the first release
  class HikiDB_rdbms < HikiDBBase
    def initialize(conf)
      @conf = conf
      @db = Sequel.connect(conf.rdbms_setting)
    end

    def open_db
      if block_given?
        @db.transaction do
          yield
        end
      else
        true
      end
      true
    end

    def close_db
      true
    end

    def pages
      @db[:page].select[:title]
    end

    def backup(page)
      @text = load(page) || ''
    end

    # Inherited from HikiDBBase
    # def delete(page)
    # end

    # Inherited from HikiDBBase
    # def md5hex(page)
    # end

    def search(word)
      raise 'Not implemented'
    end

    def load_cache(page)
      tmp = @db[:parser_cache].where(:page_title => page, :compatibility_key => Hiki::RELEASE_DATE)
      tmp.nil? ? nil : tmp.first
    end

    def save_cache(page, tokens)
      data = {
        :page_title        => page,
        :tokens            => tokens,
        :compatibility_key => Hiki::RELEASE_DATE
      }
      existing = @db[:parser_cache].filter(:page_title => page)
      if existing
        existing.update(data)
      else
        @db[:parser_cache].insert(data)
      end
    end

    def delete_cache(page)
      @db[:parser_cache].filter(:page_title => page).delete
    end

    # if md5 hash of text is not same to md5 arg,
    # it shows conflict occuring
    def store(page, text, md5, update_timestamp = true)
      # backup(page) # not implemented

      data = {:text => text.gsub(/\r\n/, "\n")}
      data[:last_modified] = Time.now if update_timestamp

      if exist?(page)
        return nil if md5 != md5hex(page)
        @db[:page].filter(:title => page).update(data)
      else
        data[:title] = page
        @db[:page].insert(data)
      end

      true
    end

    # noop
    # exists bacause called in #delete
    def unlink(page)
      # noop
    end

    def load(page)
      data = @db[:page][:title => page]
      data.nil? ? nil : data[:text]
    end

    def load_backup(page)
      nil
    end

    def exist?(page)
      @db[:page].filter(:title => page).count > 0
    end

    def backup_exist?(page)
      false
    end

    # maybe alias of #exist?
    def info_exist?(p)
      exist?(p)
    end

    def info(p)
      page = @db[:page].filter(:title => p).to_hash
      references = @db[:reference].filter(:to => p).collect {|ref| ref[:from]}
      keywords = @db[:keyword].filter(:page_title => p).collect {|kw| kw[:keyword]}
      page[:references] = references # PLURAL key name
      page[:keyword] = keywords # SINGULAR key name
    end

    def page_info
    end

    # attr is an Array or Hash, so use `each do |attribute, value|`
    # @param String p page title
    # @param Array|Hash attribute pairs like:
    #   [[:title, 'page title'], [:keyword, ['some', 'keyword', 'array']]] or
    #   {:title => 'page title', :keyword => ['some', 'keyword', 'array']}
    def set_attribute(p, attr)
      page_attr = attr.delete_if do |attribute, value|
        case attribute
        when :keyword
          set_keywords(p, value)
          true
        when :references
          set_references(p, value)
          true
        else
          false
        end
      end
      @db[:page].filter(:title => p).update(page_attr)
    end

    def get_attribute(p, attribute)
      case attribute
      when :keyword
        @db[:keyword].filter(:page_title => p).select(:keyword).all
      when :references
        @db[:reference].filter(:to => p).select(:from).all
      else
        @db[:page].filter(:title => p).select(attribute).first[attribute]
      end
    end

    # `JOIN` not used because currently called with block which handles only :title attribute
    def select
      result = []
      @db[:page].each {|info| result << info[:title] if yield info}
      result
    end

    def increment_hitcount(p)
    end

    def get_hitcount(p)
    end

    def freeze_page(p, freeze)
    end

    def is_frozen?(p)
    end

    def set_last_update(p, t)
    end

    def get_last_update(p)
    end

    def set_references(p, r)
    end

    def get_references(p)
      @db[:reference][:from => p].to_a
    end

    # Note: Implented in only this class, not in HikiDB_flatfile
    def set_keywords(page, keywords)
      # use transaction
    end

    class << self
      attr_writer :conf

      def create_tables
        max_name_size = conf.max_name_size

        db.create_table :page do
          String    :title, :size => max_name_size, :primary_key => true
          String    :editor,        :null => true,  :default => nil
          Fixnum    :count,         :null => false, :default => 0
          DateTime  :last_modified, :null => false, :default => Sequel::CURRENT_TIMESTAMP
          TrueClass :freeze,        :null => false, :default => false
          String    :text, :text => true, :null => false
        end

        db.create_table :reference do
          String :from, :key => :title, :table => :page, :null => false, :size => max_name_size
          String :to,   :key => :title, :table => :page, :null => false, :size => max_name_size, :index => true

          primary_key [:from, :to]
        end

        db.create_table :keyword do
          String :page_title, :size => max_name_size, :null => false, :key => :title, :table => :page, :index => true
          String :keyword,                            :null => false, :key => :title, :table => :page, :index => true

          primary_key [:page_title, :keyword]
        end

        db.create_table :parser_cache do
          String :page_title, :size => max_name_size, :null => false, :key => :title, :table => :page, :primary_key => true
          String :tokens, :text => true,              :null => false
          String :compatibility_key,                  :null => false
        end

        # To do: stored procedures
      end

      def drop_tables
        [:keyword, :reference, :page, :parser_cache].each {|table| db.drop_table table}
      end

      # stub :
      def insert_initial_data
        data_dir = 'data/text' # not always same to HikiDB_flatfile#pages_path
        files = Dir["#{data_dir}/*"]
      end

      private

      def conf
        @conf ||= Config.new
      end

      def db
        @db ||= Sequel.connect(conf.rdbms_setting)
      end
    end
  end
end
