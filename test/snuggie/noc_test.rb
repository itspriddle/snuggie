require 'test_helper'

context "Snuggie::NOC" do
  @@credentials = { :username => 'username', :password => 'password' }

  setup do
    @noc = Snuggie::NOC.new(@@credentials)
  end

  test "has attr_reader :params" do
    assert_attr_reader @noc, :params
  end

  test "::API_URL has a valid format" do
    assert_valid_url @noc.class::API_URL
  end

  test "#initialize sets @params" do
    params = @noc.instance_variable_get(:@params)
    assert params.is_a?(Hash)
    @@credentials.each do |key, val|
      assert_not_nil params[key]
      assert_equal params[key], val
    end
  end

  test "#initialize sets @required_params" do
    required = @noc.instance_variable_get(:@required_params)
    assert required.is_a?(Array)
    assert_equal required.size, 1
    assert_equal required.first, :ca
  end

  test "#require_params appends unique values to @require_params" do
    required = @noc.instance_eval do
      require_params :plutonium, :flux_capacitor, :ca
      @required_params
    end
    assert_equal required.size, 3
    assert required.include?(:plutonium)
    assert required.include?(:flux_capacitor)
  end

  test "#query_string raises error if required_params aren't set" do
    assert_raise RuntimeError do
      res = @noc.instance_eval do
        require_params :ca
        query_string
      end
    end
  end

  test "#missing_params returns array of missing parameters" do
    res = @noc.instance_eval do
      require_params :ca
      missing_params
    end
    assert res.is_a?(Array)
    assert_equal res.first, :ca
  end

  test "#missing_params returns nil if required_params are set" do
    res = @noc.instance_eval do
      require_params :ca
      missing_params :ca => 'foo'
    end
    assert_nil res
  end

  test "#buy_license required params" do
    assert_raise RuntimeError do
      @noc.buy_license
    end

    required = @noc.instance_eval do
      begin
        buy_license
      rescue RuntimeError
      end
      missing_params
    end
    expected = [:ca, :purchase, :ips, :toadd, :servertype, :authemail, :autorenew]
    assert_same_elements expected, required
  end
end
