require 'test_helper'

context "Snuggie::Config" do
  setup do
    @config = Snuggie::Config.new
  end

  test "#initialize sets @username" do
    assert_instance_var @config, :username
    assert_equal @config.instance_variable_get(:@username), 'username'
  end

  test "#initialize sets @password" do
    assert_instance_var @config, :password
    assert_equal @config.instance_variable_get(:@password), 'password'
  end

  test "has attr_accessor :username" do
    assert_attr_accessor @config, :username
  end

  test "has attr_accessor :password" do
    assert_attr_accessor @config, :password
  end
end
