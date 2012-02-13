# Copright 2011-2012 Fred Emmott. See COPYING file.

require 'spec_helper'

require 'my_stuff/multidb/mangling'

describe MyStuff::MultiDB::Mangling do
  before :all do
    @spec = {
      :host => 'localhost',
      :port => 3306,
      :database => 'test',
    }
    @mangled = MyStuff::MultiDB::Mangling.mangle(@spec)
  end

  describe '#mangle' do
    it 'produces a String' do
      @mangled.should be_a String
    end

    it 'should produce a valid constant name' do
      @mangled.should match /^[A-Z]/
    end

    it 'varies based on the hostname' do
      spec_a = @spec.merge(:host => 'a.example.com')
      spec_b = @spec.merge(:host => 'b.example.com')
      mangled_a = MyStuff::MultiDB::Mangling.mangle(spec_a)
      mangled_b = MyStuff::MultiDB::Mangling.mangle(spec_b)
      mangled_a.should_not == mangled_b
    end

    it 'varies based on the port' do
      spec_a = @spec.merge(:port => 3306)
      spec_b = @spec.merge(:port => 3307)
      mangled_a = MyStuff::MultiDB::Mangling.mangle(spec_a)
      mangled_b = MyStuff::MultiDB::Mangling.mangle(spec_b)
      mangled_a.should_not == mangled_b
    end

    it 'varies based on the database' do
      spec_a = @spec.merge(:database => 'herp')
      spec_b = @spec.merge(:database => 'derp')
      mangled_a = MyStuff::MultiDB::Mangling.mangle(spec_a)
      mangled_b = MyStuff::MultiDB::Mangling.mangle(spec_b)
      mangled_a.should_not == mangled_b
    end

    it 'treats string keys the same as symbol keys in the spec' do
      string_spec = Hash.new
      @spec.each do |k,v|
        string_spec[k.to_s] = v
      end
      MyStuff::MultiDB::Mangling.mangle(string_spec).should == @mangled
    end
  end

  describe '#unmangle' do
    it 'exactly reverses #mangle' do
      unmangled = MyStuff::MultiDB::Mangling.unmangle @mangled

      unmangled.should == @spec
      unmangled.should_not be @spec
    end
  end
end
