require 'test_helper'

context "Snuggie::NOC" do
  @@credentials = { :username => 'marty', :password => 'mcSUPERfly' }

  setup do
    @noc = Snuggie::NOC.new(@@credentials)
  end

  test "::API_URL has a valid format" do
    assert_valid_url @noc.class::API_URL
  end

  test "#initialize sets @credentials" do
    credentials = @noc.instance_variable_get(:@credentials)
    assert credentials.is_a?(Hash)
    @@credentials.each do |key, val|
      assert_not_nil credentials[key]
      assert_equal credentials[key], val
    end
  end

  test "#initialize uses Config to set @credentials" do
    Snuggie.configure do |c|
      c.username = 'doc'
      c.password = 'clara'
    end
    credentials = @noc.class.new.instance_variable_get(:@credentials)
    assert credentials.is_a?(Hash)
    ({ :username => 'doc', :password => 'clara' }).each do |key, val|
      assert_not_nil credentials[key]
      assert_equal credentials[key], val
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
    assert_required_params @noc, :buy_license, :ca, :purchase, :ips, :toadd, :servertype, :authemail, :autorenew
  end

  test "#list_licenses has no required params" do
    assert_no_required_params @noc, :list_licenses
  end
end
