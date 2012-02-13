# Copyright 2011-2012 Fred Emmott. See COPYING file.

module MyStuff
  module MultiDB
    module Mangling
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
        host, port, database = db.each_char.each_slice(2).reduce(String.new){ |m,*nibbles| m += "%c" % nibbles.join.hex }.split('!')
        {
          :host     => host,
          :port     => port.to_i,
          :database => database,
        }
      end

      def self.mangle spec
        'MYSTUFF_MULTIDB_DB_' + (
          "%s!%s!%s" % [
            spec[:host] || spec['host'],
            spec[:port] || spec['port'],
            spec[:database] || spec['database'],
          ]
        ).each_byte.map{ |x| "%x" % x }.join
      end
    end
  end
end
