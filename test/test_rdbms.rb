require 'rubygems'
require 'test/unit'
require 'test/unit/rr'
require 'test/unit/notify'
require 'hiki/db/rdbms'

class HikiDB_rdbms_Unit_Tests < Test::Unit::TestCase
  def setup
    conf = Object.new
    # To do: use SQLite
    stub(conf).rdbms_setting do
      {
        :adapter  => 'postgres',
        :host     => 'localhost',
        :port     => 5433,
        :database => 'hiki',
        :user     => 'hiki',
        :password => 'hiki',
        :prefix   => ''
      }
    end
    @db = Hiki::HikiDB_rdbms.new(conf)
  end

  def teardown
    @db.close_db
  end

  def test_sample
    assert false
  end

end
