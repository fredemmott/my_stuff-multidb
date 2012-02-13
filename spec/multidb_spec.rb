require 'spec_helper'

require 'my_stuff/multidb'

require 'fileutils'
require 'tmpdir'

module MySpecDB
  class Widget < ActiveRecord::Base
  end

  include MyStuff::MultiDB
end

describe MyStuff::MultiDB do
  before :all do
    @dir = Dir.mktmpdir
    @files = {}
    @specs = {}

    (1..2).each do |i|
      @files[i] = "%s/%d.sqlite" % [@dir, i]
      @specs[i] = {
        :adapter => 'sqlite3',
        :database => @files[i],
      }
      create_widgets_db @files[i]
    end
  end

  after :all do
    FileUtils.remove_entry_secure @dir
  end

  describe '#with_spec' do
    it 'provides subclasses for the models defined in the Module' do
      MySpecDB.with_spec(@specs[1]) do |db|
        lambda { db::Widget }.should_not raise_error
      end
    end

    it 'provides a writable connection' do
      MySpecDB.with_spec(@specs[1]) do |db|
        id = db::Widget.create(:name => 'foo')
        result = db::Widget.find(id)
        result.should_not be_nil
        result.name.should == 'foo'
      end
    end

    it 'separates stores data separately for each spec' do
      id_1 = nil
      id_2 = nil

      MySpecDB.with_spec(@specs[1]) do |db|
        id_1 = db::Widget.create(:name => 'herp')
      end
      MySpecDB.with_spec(@specs[2]) do |db|
        id_2 = db::Widget.create(:name => 'derp')
      end

      MySpecDB::with_spec(@specs[1]) do |db|
        widget_1 = db::Widget.find(id_1) rescue nil
        widget_2 = db::Widget.find(id_2) rescue nil

        widget_1.should_not be_nil
        widget_1.name.should == 'herp'

        if id_1 == id_2
          widget_2.name.should == 'herp'
        elsif ! widget_2.nil?
          widget_2.name.should_not == 'derp'
        end
      end

      MySpecDB::with_spec(@specs[2]) do |db|
        widget_1 = db::Widget.find(id_1) rescue nil
        widget_2 = db::Widget.find(id_2) rescue nil

        widget_2.should_not be_nil
        widget_2.name.should == 'derp'

        if id_1 == id_2
          widget_2.name.should == 'derp'
        elsif ! widget_1.nil?
          widget_1.name.should_not == 'herp'
        end
      end
    end
  end
end
