# Copyright 2011-present Fred Emmott. See COPYING file.

require 'my_stuff/multidb/connection'
require 'my_stuff/multidb/core_ext/base'

require 'base64'

require 'rubygems'
require 'active_record'

module MyStuff
  # =Example
  #
  #  module Foo
  #    class SomeTable < ActiveRecord::Base
  #    end
  #    include MyStuff::MultiDB::Unsharded
  #  end
  #  module Bar
  #    class SomeTable < ActiveRecord::Base
  #    end
  #    include MyStuff::MultiDB::Sharded
  #  end
  #
  #  Foo.with_master do |db|
  #    p db::SomeTable.where(:some_column = 'bar')
  #  end
  #  Foo.with_slave do |db|
  #    p db::SomeTable.where(:some_column = 'bar')
  #  end
  #
  #  Bar.with_master_for(id) do |db|
  #    p db::SomeTable.where(:some_column = 'bar')
  #  end
  #  Bar.with_master_for_new do |db|
  #    db::SomeTable.new do
  #       ...
  #    end
  #  end
  #  Bar.with_slave_for(id) do |db|
  #    p db::SomeTable.where(:some_column = 'bar')
  #  end
  #
  # See MyStuff::MultiDB::Unsharded and MyStuff::MultiDB::Sharded
  #
  # = Details
  #
  # When you call <tt>with_*</tt>, it:
  # * Looks for a class called MyStuff::MultiDB::MANGLED_DATABASE_NAME
  # * If it doesn't exist, it creates a new ActiveRecord::Base subclass
  # * It then looks for a module within that class with the same name as your
  #   module
  # * If it's not there:
  #   * It creates the module
  #   * It creates a subclass of each of your ActiveRecord definitions within this
  #     module
  #   * It delegates connection handling to the database class
  # * It then returns the database class
  #
  # So, you end up with an ActiveRecord class like:
  # MyStuff::MultiDB::MANGLED_DATABASE_NAME::YourModule::YourClass
  module MultiDB
    def self.included othermod # :nodoc:
      class <<othermod
        def with_spec spec, &block
          MyStuff::MultiDB.with_spec(self, spec, &block)
        end
      end
    end

    def self.with_spec original_module, spec, &block # :nodoc:
      ar_base = Connection.base_class_for_spec(spec)
      rebased_module = ar_base.rebased_module(original_module)

      ar_base.connection_pool.with_connection do
        if block.arity == 1
          block.call rebased_module
        else
          block.call rebased_module, spec
        end
      end
    end
  end
end

require 'my_stuff/multidb/sharded'
require 'my_stuff/multidb/unsharded'
