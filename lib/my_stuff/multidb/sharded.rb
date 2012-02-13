# Copyright 2011-present Fred Emmott. See COPYING file.

require 'my_stuff/multidb'

module MyStuff
  module MultiDB
    module Sharded
      def self.included othermod # :nodoc:
        othermod.send :include, MyStuff::MultiDB

        class <<othermod
          def with_master_for id, &block
            MyStuff::MultiDB.with_spec(
              self,
              self.spec_for_master(id),
              &block
            )
          end

          def with_master_for_new &block
            MyStuff::MultiDB.with_spec(
              self,
              self.spec_for_new,
              &block
            )
          end

          def with_slave_for id, &block
            MyStuff::MultiDB.with_spec(
              self,
              self.spec_for_slave(id),
              &block
            )
          end

          def spec_for_new; raise NotImplementedError.new; end
          def spec_for_master(shard_id); raise NotImplementedError.new; end
          def spec_for_slave(shard_id); raise NotImplementedError.new; end
        end
      end
    end
  end
end
