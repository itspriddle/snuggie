require 'rubygems'
require 'snuggie'
require 'test/unit'
require 'fakeweb'
require 'php_serialize'

begin
  require 'turn'
rescue LoadError
end

FakeWeb.allow_net_connect = false

# test/spec/mini 3
# Based on http://gist.github.com/25455
def context(*args, &block)
  return super unless (name = args.first) && block
  klass = Class.new(Test::Unit::TestCase) do
    def self.test(name, &block)
      name = " #{name}" unless %w[: # .].include?(name[0].chr)
      define_method("test: #{self.name}#{name}", &block) if block
    end
    def self.setup(&block) define_method(:setup, &block) end
    def self.teardown(&block) define_method(:teardown, &block) end
  end
  (class << klass; self end).send(:define_method, :name) { name }
  klass.class_eval &block
end


def mock_request(url, options = {})
  FakeWeb.register_uri(:get, url, options)
end

# Asserts that the given object has an instance variable for var
#
#   class Foo
#     def initialize
#       @bar = :bar
#     end
#   end
#
#   assert_instance_var(Foo.new, :bar) => passes
def assert_instance_var(obj, var)
  assert_not_nil obj.instance_variable_get("@#{var}")
end

# Asserts that the given object has an attr_accessor for method
#
#   class Foo
#     attr_accessor :bar
#   end
#
#   assert_attr_accesor(Foo.new, :bar) => passes
def assert_attr_accessor(obj, method)
  assert_attr_reader obj, method
  assert_attr_writer obj, method
end

# Asserts that the given object has an attr_reader for method
#
#   class Foo
#     attr_writer :bar
#   end
#
#   assert_attr_reader(Foo.new, :bar) => passes
def assert_attr_reader(obj, method)
  assert_respond_to obj, method
  assert_equal obj.send(method), obj.instance_variable_get("@#{method}")
end

# Asserts that the given object has an attr_writer for method
#
#   class Foo
#     attr_writer :bar
#   end
#
#   assert_attr_writer(Foo.new, :bar) => passes
def assert_attr_writer(obj, method)
  assert_respond_to obj, "#{method}="
end

# Asserts that the given string is a valid URL
#
#   assert_valid_url('http://google.com') => passes
def assert_valid_url(string)
  assert string.to_s.match(/https?:\/\/[\S]+/)
end

# From https://github.com/thoughtbot/shoulda-context/blob/master/lib/shoulda/context/assertions.rb
# Asserts that two arrays contain the same elements, the same number of times.  Essentially ==, but unordered.
#
#   assert_same_elements([:a, :b, :c], [:c, :a, :b]) => passes
def assert_same_elements(a1, a2, msg = nil)
  [:select, :inject, :size].each do |m|
    [a1, a2].each {|a| assert_respond_to(a, m, "Are you sure that #{a.inspect} is an array?  It doesn't respond to #{m}.") }
  end

  assert a1h = a1.inject({}) { |h,e| h[e] ||= a1.select { |i| i == e }.size; h }
  assert a2h = a2.inject({}) { |h,e| h[e] ||= a2.select { |i| i == e }.size; h }

  assert_equal(a1h, a2h, msg)
end

# Asserts that the given collection contains item x.  If x is a regular expression, ensure that
# at least one element from the collection matches x.  +extra_msg+ is appended to the error message if the assertion fails.
#
#   assert_contains(['a', '1'], /\d/) => passes
#   assert_contains(['a', '1'], 'a') => passes
#   assert_contains(['a', '1'], /not there/) => fails
def assert_contains(collection, x, extra_msg = "")
  collection = Array(collection)
  msg = "#{x.inspect} not found in #{collection.to_a.inspect} #{extra_msg}"
  case x
  when Regexp
    assert(collection.detect { |e| e =~ x }, msg)
  else
    assert(collection.include?(x), msg)
  end
end

# Asserts that the given collection does not contain item x.  If x is a regular expression, ensure that
# none of the elements from the collection match x.
def assert_does_not_contain(collection, x, extra_msg = "")
  collection = Array(collection)
  msg = "#{x.inspect} found in #{collection.to_a.inspect} " + extra_msg
  case x
  when Regexp
    assert(!collection.detect { |e| e =~ x }, msg)
  else
    assert(!collection.include?(x), msg)
  end
end
