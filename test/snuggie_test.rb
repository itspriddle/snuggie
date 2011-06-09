require 'test_helper'

context "Snuggie" do
  setup do
    Snuggie.config = Snuggie::Config.new
  end

  test "::Version has a valid format" do
    assert Snuggie::Version.match(/\d+\.\d+\.\d+/)
  end

  test "has class attr_accessor :config" do
    assert_attr_accessor Snuggie, :config
  end

  test "::config defaults to Config.new" do
    assert Snuggie.config.is_a?(Snuggie::Config)
  end

  test "::configure sets config with a block" do
    Snuggie.configure do |c|
      c.username = 'mcfly'
      c.password = 'b4ck1nt1m3'
    end

    assert Snuggie.configure.is_a?(Snuggie::Config)
    assert_equal Snuggie.config.username, 'mcfly'
    assert_equal Snuggie.config.password, 'b4ck1nt1m3'
  end

end
