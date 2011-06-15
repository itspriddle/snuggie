require 'test_helper'

context "Snuggie::Config" do
  setup do
    @config = Snuggie::Config.new
  end

  test "has attr_accessor :username" do
    assert_attr_accessor @config, :username
  end

  test "has attr_accessor :password" do
    assert_attr_accessor @config, :password
  end
end
