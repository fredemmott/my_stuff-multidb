# Copyright 2011-present Fred Emmott. See COPYING file.

require 'my_stuff/multidb/mangling'
require 'my_stuff/multidb/core_ext/base'

require 'rubygems'
require 'active_record'

module MyStuff
  module MultiDB
    module Connections; end

    class Connection < ActiveRecord::Base
      class << self
        def base_class_for_spec spec
          name = MyStuff::MultiDB::Mangling.mangle(spec).to_sym
          if Connections.const_defined?(name)
            return Connections.const_get(name)
          end

          connection = Class.new(self)
          Connections.const_set(name, connection)
          connection.establish_connection(spec)
          connection
        end

        def abstract_class?
          true
        end

        def rebased_module original_module
          name = original_module.name.gsub(':', '__').to_sym

          if have_rebased_module?(name)
            self.const_get(name)
          else
            self.rebase_module! name, original_module
          end
        end

        def rebased_model name, original_module, rebased_module
          if rebased_module.const_defined? name
            rebased_module.const_get(name)
          else
            self.rebase_model! name, original_module, rebased_module
          end
        end

        protected

        def rebase_model! name, original_module, rebased_module
          name = name.to_sym
          original = original_module.const_get(name)

          rebased = Class.new(original)
          rebased_module.const_set(name, rebased)
          rebased.send :include, MyStuff::MultiDB::CoreExt::Base

          # Make associations work.
          rebased.reflect_on_all_associations.each do |reflection|
            rebased.send(
              reflection.macro, # eg :has_one
              reflection.name, # eg :some_table
              reflection.options
            )
          end

          return rebased
        end

        def rebase_module! name, original_module
          ar_base = self
          rebased = Module.new
          ar_base.const_set(name, rebased)

          # Generate wrapper classes on demand
          def rebased.const_missing (name)
            MyStuff::MultiDB::Connection.rebased_model(
              name,
              muggle,
              magic_database
            )
          end

          # Not using define_singleton_method, as that's not in 1.8.7
          singleton = class << rebased; self; end
          singleton.send(:define_method, :magic_database) { ar_base }
          singleton.send(:define_method, :muggle) { original_module }

          return rebased
        end

        def have_rebased_module? name
          # 1.8.7: const_defined? does not include constants defined
          #   in other modules, and it only takes 1 arg
          # 1.9: it does include, and needs a second argument to change
          #   this.
          old_const_defined = self.method(:const_defined?).arity == 1
          new_const_defined = !old_const_defined
          return (
            (old_const_defined && self.const_defined?(name)) ||
            (new_const_defined && self.const_defined?(name, false))
          )
        end
      end
    end
  end
end
