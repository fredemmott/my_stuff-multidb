unless RUBY_VERSION.start_with? '1.8.'
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'rubygems'
require 'sqlite3'

def create_widgets_db path
  SQLite3::Database.new(path).execute <<-SQL
    create table widgets(
     id integer primary key,
     name varchar(30)
   );
SQL
end
