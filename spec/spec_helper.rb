unless RUBY_VERSION.start_with? '1.8.'
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end
