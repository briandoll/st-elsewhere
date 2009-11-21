require 'rubygems'
require 'test/unit'
require 'active_record'
require 'rr'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end