require 'spec_helper'

require 'my_stuff/multidb/sharded'

require 'fileutils'
require 'tmpdir'

module ShardedDB
  class Widget < ActiveRecord::Base
  end

  include MyStuff::MultiDB::Sharded
  class <<self
    attr_accessor :db_dir
    def db_file shard_id
      '%s/%d.sqlite' % [self.db_dir, shard_id]
    end

    def counters
      @counters ||= Hash.new{|h,k| h[k] = 0}
    end

    def spec_for_new
      counters[:new] += 1
      my_spec_for(0)
    end

    def spec_for_master shard_id
      counters[:master] += 1
      my_spec_for(shard_id)
    end

    def spec_for_slave shard_id
      counters[:slave] += 1
      my_spec_for(shard_id)
    end

    def my_spec_for shard_id
      {
        :adapter => 'sqlite3',
        :database => self.db_file(shard_id),
      }
    end
  end
end

describe MyStuff::MultiDB::Sharded do
  before :all do
    ShardedDB.db_dir = Dir.mktmpdir
    create_widgets_db ShardedDB.db_file(0)
    create_widgets_db ShardedDB.db_file(1)
  end

  after :all do
    FileUtils.remove_entry_secure ShardedDB.db_dir
  end

  describe '#with_master_for' do
    it 'calls #spec_for_master' do
      before_count = ShardedDB.counters[:new]
      ShardedDB.with_master_for(0) {}
      ShardedDB.counters[:master].should == before_count + 1
    end

    it 'does not call other spec methods' do
      before_new = ShardedDB.counters[:new]
      before_slaves = ShardedDB.counters[:slave]

      ShardedDB.with_master_for(0) {}

      ShardedDB.counters[:new].should == before_new
      ShardedDB.counters[:slave].should == before_slaves
    end

    it 'provides distinct databases for different shard ids' do
      id_0 = nil
      id_1 = nil

      ShardedDB.with_master_for(0) do |db|
        id_0 = db::Widget.create(:name => 'shard 0').id
        id_0.should be_a Fixnum
      end

      ShardedDB.with_master_for(1) do |db|
        result_0 = db::Widget.find(id_0) rescue nil
        if result_0
          result_0.name.should_not == 'shard 0'
        end
        id_1 = db::Widget.create(:name => 'shard 1').id
      end

      ShardedDB.with_master_for(0) do |db|
        result_0 = db::Widget.find(id_0) rescue nil
        result_0.should_not be_nil
        result_0.name.should == 'shard 0'

        result_1 = db::Widget.find(id_1) rescue nil
        if result_1
          result_1.name.should_not == 'shard 1'
        end
      end
    end
  end

  describe '#with_slave_for' do
    it 'calls #spec_for_slave' do
      before_count = ShardedDB.counters[:slave]
      ShardedDB.with_slave_for(0) {}
      ShardedDB.counters[:slave].should == before_count + 1
    end

    it 'does not call other spec methods' do
      before_new = ShardedDB.counters[:new]
      before_master = ShardedDB.counters[:master]

      ShardedDB.with_slave_for(0) {}

      ShardedDB.counters[:new].should == before_new
      ShardedDB.counters[:master].should == before_master
    end

    it 'correlated shard IDs with master correctly' do
      id_0 = nil
      ShardedDB.with_master_for(0) do |db|
        id_0 = db::Widget.create(:name => 'herp').id
      end

      ShardedDB.with_slave_for(0) do |db|
        result = db::Widget.find(id_0) rescue nil
        result.should_not be nil
        result.name.should == 'herp'
      end
    end
  end

  describe '#with_master_for_new' do
    it 'calls #spec_for_new' do
      before_count = ShardedDB.counters[:new]
      ShardedDB.with_master_for_new {}
      ShardedDB.counters[:new].should == before_count + 1
    end

    it 'does not call other spec methods' do
      before_masters = ShardedDB.counters[:master]
      before_slaves = ShardedDB.counters[:slave]

      ShardedDB.with_master_for_new {}

      ShardedDB.counters[:master].should == before_masters
      ShardedDB.counters[:slave].should == before_slaves
    end

    it 'provides subclasses for the models defined in the Module' do
      ShardedDB.with_master_for_new do |db|
        lambda { db::Widget }.should_not raise_error
      end
    end

    it 'provides a writable connection' do
      ShardedDB.with_master_for_new do |db|
        id = db::Widget.create(:name => 'foo')
        result = db::Widget.find(id)
        result.should_not be_nil
        result.name.should == 'foo'
      end
    end
  end
end
