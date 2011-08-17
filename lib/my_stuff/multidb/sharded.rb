# Copyright 2011-present Fred Emmott. All Rights Reserved.

module MyStuff
  module MultiDB
    module Sharded
      def self.included othermod # :nodoc:
        othermod.send :include, MyStuff::MultiDB
        class <<othermod
          def sharded?; true; end;
          def with_master_for id
            MyStuff::MultiDB.with_db(
              self, id, :writable
            ) { |*args| yield *args}
          end
          def with_master_for_new
            MyStuff::MultiDB.with_db(
              self, :new, :read_only
            ) { |*args| yield *args}
          end
          def with_slave_for id
            MyStuff::MultiDB.with_db(
              self, id, :read_only
            ) { |*args| yield *args}
          end
        end
      end
    end
  end
end
