# Copyright 2011-present Fred Emmott. See COPYING file.

module MyStuff
  module MultiDB
    # Mixin for databases with no sharding (eg ServiceLocator, which defines the sharding).
    #
    # See MyStuff::MultiDB for an example.
    #
    # Including this defines <tt>with_master</tt> and <tt>with_slave</tt>.
    module Unsharded
      def self.included othermod # :nodoc:
        othermod.send :include, MyStuff::MultiDB
        class <<othermod
          def sharded?; false; end;
          def with_master
            MyStuff::MultiDB.with_db(
              self, :unsharded, :writable
            ) { |*args| yield *args }
          end
          def with_slave
            MyStuff::MultiDB.with_db(
              self, :unsharded, :read_only
            ) { |*args| yield *args}
          end
        end
      end
    end
  end
end
