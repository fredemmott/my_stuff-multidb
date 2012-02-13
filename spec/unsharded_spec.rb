
require 'my_stuff/multidb/unsharded'

require 'fileutils'
require 'tmpdir'

require 'rubygems'
require 'sqlite3'

module UnshardedDB
  class Widget < ActiveRecord::Base
  end

  class <<self
    attr_accessor :db_path
    def counters
      @counters ||= Hash.new{|h,k| h[k] = 0}
    end

    def db_file
      db_path + '/test.sqlite'
    end

    def spec_for_master shard_id
      counters[:master] += 1
      self.my_spec_for(shard_id)
    end

    def spec_for_slave shard_id
      counters[:slave] += 1
      self.my_spec_for(shard_id)
    end

    def my_spec_for shard_id
      {
        :adapter => 'sqlite3',
        :database => db_file
      }
    end
  end

  include MyStuff::MultiDB::Unsharded
end

describe MyStuff::MultiDB::Unsharded do
  before :all do
    UnshardedDB.db_path = Dir.mktmpdir
    SQLite3::Database.new(UnshardedDB.db_file).execute <<-SQL
      create table widgets(
        id integer primary key,
        name varchar(30)
      );
SQL
  end

  after :all do
    FileUtils.remove_entry_secure UnshardedDB.db_path
  end

  describe '#with_master' do
    it 'calls spec_for_master' do
      before_count = UnshardedDB.counters[:master]
      UnshardedDB.with_master {}
      UnshardedDB.counters[:master].should == before_count + 1
    end

    it 'does not call spec_for_slave' do
      before_count = UnshardedDB.counters[:slave]
      UnshardedDB.with_master {}
      UnshardedDB.counters[:slave].should == before_count
    end

    it 'provides subclasses for the models defined in the Module' do
      UnshardedDB.with_master do |db|
        lambda { db::Widget }.should_not raise_error
      end
    end

    it 'provides a writable connection' do
      UnshardedDB.with_master do |db|
        id = db::Widget.create(:name => 'foo')
        result = db::Widget.find(id)
        result.should_not be_nil
        result.name.should == 'foo'
      end
    end
  end

  describe '#with_slave' do
    it 'calls spec_for_slave' do
      before_count = UnshardedDB.counters[:slave]
      UnshardedDB.with_slave {}
      UnshardedDB.counters[:slave].should == before_count + 1
    end

    it 'does not call spec_for_master' do
      before_count = UnshardedDB.counters[:master]
      UnshardedDB.with_slave{}
      UnshardedDB.counters[:master].should == before_count
    end

    it 'provides subclasses for the models defined in the Module' do
      UnshardedDB.with_slave do |db|
        lambda { db::Widget }.should_not raise_error
      end
    end

    it 'provides a writable connection' do
      id = nil
      UnshardedDB.with_master do |db|
        id = db::Widget.create(:name => 'foo')
      end
      UnshardedDB.with_slave do |db|
        result = db::Widget.find(id)
        result.should_not be_nil
        result.name.should == 'foo'
      end
    end
  end
end
