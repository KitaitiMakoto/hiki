require 'hiki/config'
require 'hiki/storage'
require 'rubygems'
require 'sequel'

module Hiki
  class HikiDB_rdbms < HikiDBBase
    TABLES = [:parser_cache, :backup, :keyword, :reference, :page]

    def initialize(conf)
      @conf = conf
    end

    def open_db
      @db = Sequel.connect(@conf.rdbms_setting)
      begin
        if block_given?
          yield
        else
          true
        end
      ensure
        close_db
      end
      true
    end

    def close_db
      @db.disconnect
    end

    def pages
      @db[:page].select(:name).all
    end

    # TODO: To implement appropriate algorithm for RDBMS
    def search(w)
      super
    end

    def load_cache(page)
      tmp = @db[:parser_cache].where(:page_name => page, :compatibility_key => Hiki::RELEASE_DATE)
      tmp.nil? ? nil : tmp.first
    end

    def save_cache(page, tokens)
      data = {
        :page_name         => page,
        :tokens            => tokens,
        :compatibility_key => Hiki::RELEASE_DATE
      }
      @db.transaction do
        existing = @db[:parser_cache].filter(:page_name => page)
        if existing
          existing.update(data)
        else
          @db[:parser_cache].insert(data)
        end
      end
    end

    def delete_cache(page)
      @db[:parser_cache].filter(:page_name => page).delete
    end

    def store(page, text, md5, update_timestamp = true)
      # backup(page) # Why called in HikiDB_flatfile#store ?

      data = {:text => text.gsub(/\r\n/, "\n")}
      data[:last_modified] = Time.now if update_timestamp

      if exist?(page)
        return nil if md5 != md5hex(page)
        @db.transaction do # required because #save_backup accesses database
          save_backup(page) if update_timestamp
          @db[:page].filter(:name => page).update(data)
        end
      else
        data[:name] = data[:title] = page
        @db[:page].insert(data)
      end

      true
    end

    def unlink(page)
      @db.transaction do # required because #save_backup accesses database
        save_backup(page)
        @db[:page].filter(:name => page).delete
      end
    end

    def load(page)
      data = @db[:page][:name => page]
      data.nil? ? nil : data[:text]
    end

    def load_backup(page)
      if bu = @db[:backup][:page_name => page]
        bu[:text]
      end
    end

    def exist?(page)
      ! @db[:page][:name => page].nil?
    end
    alias info_exist? exist?

    def backup_exist?(page)
      ! @db[:backup][:page_name => page].nil?
    end

    def info(p)
      @db.transaction do
        page = @db[:page].filter(:name => p).to_hash
        references = @db[:reference].filter(:to => p).collect {|ref| ref[:from]}
        keywords = @db[:keyword].filter(:page_name => p).collect {|kw| kw[:keyword]}
      end
      page[:references] = references # PLURAL key name
      page[:keyword] = keywords # SINGULAR key name
    end

    def page_info
      h = []
      dataset = @db[:page]
      dataset.left_outer_join(:reference, :to => :name)
      dataset.left_outer_join(:keyword, :page_name => :name)
      dataset.all.each do |record|
        h << { record[:name] => record }
      end
      h
    end

    def set_attribute(p, attr)
      page_attr = attr.inject({}) { |filtered, (attribute, value)|
        case attribute
        when :keyword
          set_keywords(p, value)
          filtered
        when :references
          set_references(p, value)
          filtered
        else
          filtered[attribute] = value
          filtered
        end
      }
      @db[:page].filter(:name => p).update(page_attr)
    end

    def get_attribute(p, attribute)
      case attribute
      when :keyword
        @db[:keyword].filter(:page_name => p).select_map(:keyword)
      when :references
        @db[:reference].filter(:to => p).select(:from).all
      else
        record = @db[:page].filter(:name => p).select(attribute).first
        record[attribute] unless record.nil?
      end
    end

    # `JOIN` not used because, on current implementation, called with block which handles only :name attribute
    def select
      result = []
      @db[:page].each {|info| result << info[:name] if yield info}
      result
    end

    def increment_hitcount(p)
      raise NotImplementedError
    end

    def get_hitcount(p)
      raise NotImplementedError
    end

    def freeze_page(p, freeze)
      set_attribute(p, [[:freeze, freeze]])
    end

    def is_frozen?(p)
      get_attribute(p, :freeze)
    end

    def set_last_update(p, t)
      set_attribute(p, [[:last_modified, t]])
    end

    def get_last_update(p)
      page = @db[:page][:name => p]
      page && page[:last_modified]
    end

    def set_references(p, r)
      @db.transaction do
        old_refs = @db[:reference].filter(:from => p).select_map(:to)
        del_refs = old_refs - r
        new_refs = r - old_refs

        new_data = new_refs.collect {|ref| {:from => p, :to => ref}}
        @db[:reference].filter(:from => p, :to => del_refs).delete
        @db[:reference].multi_insert(new_data)
      end
    end

    def get_references(p)
      @db[:reference].filter(:to => p).select_map(:from)
    end

    def set_keywords(page, keywords)
      @db.transaction do
        old_kws = @db[:keyword].filter(:page_name => page).select_map(:keyword)
        del_kws = old_kws - keywords
        new_kws = keywords - old_kws

        new_data = new_kws.collect {|kw| {:page_name => page, :keyword => kw}}
        @db[:keyword].filter(:page_name => page, :keyword => del_kws).delete
        @db[:keyword].multi_insert(new_data)
      end
    end

    private

    # Don't use transaction in this method
    # Use transaction out of it if needed
    def save_backup(page)
      text = @db[:page].filter(:name => page).select_map(:text)
      bu = @db[:backup].filter(:page_name => page)
      if bu.empty?
        @db[:backup].insert(:page_name => page, :text => text)
      else
        bu.update(:text => text)
      end
    end

    class << self
      attr_writer :conf

      def create_tables
        max_name_size = conf.max_name_size

        db.create_table :page do
          String    :name, :size => max_name_size,  :primary_key => true
          String    :title, :size => max_name_size, :null => false, :unique => true
          String    :editor,        :null => true,  :default => nil
          Fixnum    :count,         :null => false, :default => 0
          DateTime  :last_modified, :null => false, :default => Sequel::CURRENT_TIMESTAMP
          TrueClass :freeze,        :null => false, :default => false
          String    :text, :text => true, :null => false
        end

        db.create_table :reference do
          String :from, :key => :name, :table => :page, :null => false, :size => max_name_size
          String :to,   :key => :name, :table => :page, :null => false, :size => max_name_size, :index => true

          primary_key [:from, :to]
        end

        db.create_table :keyword do
          String :page_name, :size => max_name_size, :null => false, :key => :name, :table => :page, :index => true
          String :keyword,                           :null => false, :index => true

          primary_key [:page_name, :keyword]
        end

        db.create_table :backup do
          String :page_name, :size => max_name_size, :primary_key => true
          String :text, :text => true, :null => false
        end

        db.create_table :parser_cache do
          String :page_name, :size => max_name_size, :null => false, :key => :name, :table => :page, :primary_key => true
          String :tokens, :text => true,              :null => false
          String :compatibility_key,                  :null => false
        end

        # TODO: stored procedures
      end

      def drop_tables
        TABLES.each do |table|
          db.drop_table table if db.table_exists?(table)
        end
      end

      def insert_initial_data
        require 'pathname'

        # not always same to HikiDB_flatfile#pages_path
        files = Pathname.glob('data/text/*')
        data = files.collect {|file|
          name = file.basename.to_s
          {:name => name, :title => name, :text => file.read}
        }
        db[:page].multi_insert data
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
