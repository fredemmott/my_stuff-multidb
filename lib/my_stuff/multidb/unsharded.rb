# Copyright 2011-present Fred Emmott. See COPYING file.
#
require 'my_stuff/multidb'

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
          def with_master &block
            MyStuff::MultiDB.with_spec(
              self,
              self.spec_for_master,
              &block
            )
          end

          def with_slave &block
            MyStuff::MultiDB.with_spec(
              self,
              self.spec_for_slave,
              &block
            )
          end

          def spec_for_master; raise NotImplementedError.new; end
          def spec_for_slave; raise NotImplementedError.new; end
        end
      end
    end
  end
end
