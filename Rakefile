$LOAD_PATH << File.dirname(__FILE__)
require 'rake/testtask'

task :default => :test

Rake::TestTask.new

namespace :db do
  require 'hiki/config'
  require 'hiki/db/rdbms'

  desc 'Create tables and insert initial data'
  task :setup => [:drop_tables, :create_tables, :init_data]

  desc 'Create tables'
  task :create_tables do
    Hiki::HikiDB_rdbms.create_tables
  end

  desc 'Drop tables'
  task :drop_tables do
    Hiki::HikiDB_rdbms.drop_tables
  end

  desc 'Insert initial data'
  task :init_data do
    Hiki::HikiDB_rdbms.insert_initial_data
  end
end
