# Copyright 2011-present Fred Emmott. All Rights Reserved.

module MyStuff
  module MultiDB
    module Base # :nodoc:
      def connection
        self.class.connection
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end
     
      module ClassMethods
        def magic_database
          @magic_database ||= self.name.split('::').tap(&:pop).join('::').constantize.magic_database
        end

        def arel_engine
          magic_database.arel_engine
        end

        def connection
          magic_database.connection
        end

        def abstract_class?; true; end

        def model_name
          # Rails form_for wants this
          ActiveModel::Name.new(
            self.name.split('::').last.tap{|s| def s.name; self; end}
          )
        end

        def inherited(child)
          def child.abstract_class?; false; end
          super
        end
      end
    end
  end
end
