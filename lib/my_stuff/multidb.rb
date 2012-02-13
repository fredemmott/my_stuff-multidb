# Copyright 2011-present Fred Emmott. See COPYING file.

require 'base64'

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
    def self.open_connections
      Hash.new.tap do |result|
        constants.each do |name|
          if name.to_s.starts_with? 'MYSTUFF_MULTIDB_DB'
            klass = const_get(name, false)
            checked_out = klass.connection_pool.instance_eval { @checked_out.size }
            result[name] = checked_out if checked_out > 0
          end
        end
      end
    end

    # Takes a module name and converts it to connection details.
    #
    # Example:
    # mangled::    <tt>MyStuff::MultiDB::MYSTUFF_MULTIDB_DB_747970686f6e2e66726564656d6d6f74742e636f2e756b2c333330362c747474::ServiceLocator::Tier</tt>
    # unmanagled:: <tt>MyStuff::MultiDB::<mysql://typhon.fredemmott.co.uk:3306/ttt>::ServiceLocator::Tier</tt>
    #
    # The initscript cat-log and tail-log commands will do this unmanggling for you.
    def self.unmangle name
      db = name.sub /^:?MYSTUFF_MULTIDB_DB_/, ''
      # Format: "MYSTUFF_MULTIDB_DB_" + hex("host,port,database")
      junk, host, port, database = db.each_char.each_slice(2).reduce(String.new){ |m,*nibbles| m += "%c" % nibbles.join.hex }.split('!')
      {
        :host     => host,
        :port     => port.to_i,
        :database => database,
      }
    end

    def self.included othermod # :nodoc:
      class <<othermod
        def with_slave *args; raise NotImplementedError.new "Available in MyStuff::MultiDB::Unsharded"; end
        def with_master *args; raise NotImplementedError.new "Available in MyStuff::MultiDB::Unsharded"; end
        def with_master_for *args; raise NotImplementedError.new "Available in MyStuff::MultiDB::Sharded"; end
        def with_master_for_new; raise NotImplementedError.new "Available in MyStuff::MultiDB::Sharded"; end
        def with_slave_for *args; raise NotImplementedError.new "Available in MyStuff::MultiDB::Sharded"; end
        def sharded?; raise NotImplementedError.new; end
      end
    end

    # Fetch/create the magic classes.
    def self.for_spec spec, mod # :nodoc:
      db_key = ("MYSTUFF_MULTIDB_DB_" + ("!%s!%s!%s" % [
          spec[:host] || spec['host'],
          spec[:port] || spec['port'],
          spec[:database] || spec['database'],
        ]
      ).each_byte.map{ |x| "%x" % x }.join).to_sym

      # db: class representing the logical database
      if self.const_defined? db_key
        db = self.const_get(db_key)
      else
        l 'connecting to database: ', spec
        db = Class.new ActiveRecord::Base
        def db.abstract_class?; true; end
        self.const_set(db_key, db)
        db.establish_connection(spec)
      end

      mod_key = mod.name.split(':').last.to_sym
      # db_mod: class representing the module from the AR definition
      if db.const_defined? mod_key, false
        db_mod = db.const_get(mod_key, false)
      else
        db_mod = Module.new
        db.const_set(mod_key, db_mod)
        db_mod.send(:define_singleton_method, :magic_database) { db }
        db_mod.send(:define_singleton_method, :muggle) { mod }

        # klass: a specific table's AR class
        def db_mod.const_missing name
          klass = muggle.const_get(name)
          klass_sym = klass.name.split(':').last.to_sym

          # subklass: klass tied to a specific DB
          subklass = Class.new(klass)
          const_set klass_sym, subklass
          define_singleton_method(klass_sym) { subklass }

          subklass.send :include, MyStuff::MultiDB::Base

          # Make associations work.
          klass.reflect_on_all_associations.each do |reflection|
            subklass.send(
              reflection.macro, # eg :has_one
              reflection.name, # eg :some_table
              reflection.options
            )
          end

          return subklass
        end
      end

      return db_mod
    end

    def self.with_spec db, spec # :nodoc:
      klass = db.for_spec(spec)

      klass.magic_database.connection_pool.with_connection do
        yield klass, spec
      end
    end

    protected
    def self.with_db db, id, writable # :nodoc:
      if writable == :writable
        if id == :new
          spec = db.spec_for_new
        else
          spec = db.spec_for_master(id)
        end
      elsif writable == :read_only
        spec = db.spec_for_slave(id)
      end

      with_spec(db, spec) do |*args|
        yield *args
      end
    end
  end
end

require 'my_stuff/multidb/base'
require 'my_stuff/multidb/sharded'
require 'my_stuff/multidb/unsharded'
