require 'test_helper'

context "Snuggie::NOC" do
  TEST_CREDENTIALS = { :username => 'marty', :password => 'mcSUPERfly' }

  setup do
    @noc = Snuggie::NOC.new(TEST_CREDENTIALS)
  end

  def mock_query_url(params = {})
    @noc.class::API_URL + '?' + @noc.instance_eval { query_string(params) }
  end

  test "::API_URL has a valid format" do
    assert_valid_url @noc.class::API_URL
  end

  test "#initialize sets @credentials" do
    credentials = @noc.instance_variable_get(:@credentials)
    assert credentials.is_a?(Hash)
    TEST_CREDENTIALS.each do |key, val|
      assert credentials.has_key?(key)
      assert_equal val, credentials[key]
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
      assert credentials.has_key?(key)
    end

    Snuggie.configure do |c|
      c.username = nil
      c.password = nil
    end
    assert_equal @noc.class.new.instance_variable_get(:@credentials), Hash.new
  end

  test "#require_params returns true if all params are set" do
    a1 = @noc.instance_eval do
      require_params({ :fuel => :plutonium, :date => 1955 }, [:fuel, :date])
    end
    assert a1
  end

  test "#require_one_of returns true if one param is set" do
    a1 = @noc.instance_eval do
      require_one_of({ :date => 1955, :fuel => :plutonium }, [:fusion, :fuel])
    end
    assert a1
  end

  test "#query_string" do
    params = {
      :date     => 1955,
      :fuel     => :plutonium,
      :username => 'marty',
      :password => 'mcSUPERfly'
    }

    query = @noc.instance_eval do
      query_string(params)
    end

    assert_match /date=1955/,          query
    assert_match /fuel=plutonium/,     query
    assert_match /nocname=marty/,      query
    assert_match /nocpass=mcSUPERfly/, query

    assert_no_match /username/, query
    assert_no_match /password/, query
  end

  test "#commit requires all :require params" do
    mock_request(mock_query_url)
    assert_raise(Snuggie::Errors::MissingArgument) do
      @noc.instance_eval do
        commit({}, :require => :fuel)
      end
    end

    params = { :fuel => :plutonium }
    mock_request(mock_query_url(params))
    assert_nothing_raised do
      @noc.instance_eval do
        commit(params, :require => :fuel)
      end
    end
  end

  test "#commit requires one of :require_one params" do
    p1 = { :date => 1955 }
    mock_request(mock_query_url(p1))
    assert_raise(Snuggie::Errors::MissingArgument) do
      @noc.instance_eval do
        commit(p1, :require_one => :fuel)
      end
    end

    p2 = { :date => 1955, :fuel => :plutonium }
    mock_request(mock_query_url(p2))
    assert_nothing_raised do
      @noc.instance_eval do
        commit(p2, :require_one => :fuel)
      end
    end
  end

  test "#commit returns a hash if PHP.unserialize works" do
    p1 = { :date => 1955 }
    mock_request(mock_query_url(p1), :body => PHP.serialize(:status => :success))
    res = @noc.instance_eval do
      commit(p1, :require => :date)
    end
    assert res.has_key?('status')
    assert_equal 'success', res['status']
  end

  test "#commit returns HTTP body if PHP.unserialize fails" do
    p1 = { :date => 1955 }
    mock_request(mock_query_url(p1), :body => "not a PHP serialized string")
    res = @noc.instance_eval do
      commit(p1, :require => :date)
    end
    assert_equal 'not a PHP serialized string', res
  end

  test "#buy_license required params" do
    params = {
      :ip            => '127.0.0.1',
      :months_to_add => 1,
      :servertype    => :dedicated,
      :authemail     => 'marty@hilldale.edu',
      :autorenew     => true
    }
    mock_request(:buy_license)
    assert_raise(Snuggie::Errors::MissingArgument, "requires args") do
      @noc.buy_license
    end

    res = @noc.buy_license(params)
    assert res.is_a?(Hash)
    assert_equal '1M', res['added']
    assert_equal 'YES', res['autorenew']
    assert_equal 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX', res['license']
    assert_equal 1308062889, res['time']
    assert_equal -48.0, res['bal']
    assert_equal 2, res['rate']
    assert_equal 99999, res['actid']
    assert_equal '127.0.0.1', res['ip']
    assert_equal 99999, res['lid']
    assert_equal 2, res['amt']
  end

  test "#refund" do
    mock_request(:refund)
    assert_raise(Snuggie::Errors::MissingArgument, "requires actid") do
      @noc.refund
    end

    res = @noc.refund :actid => 99999
    assert res.is_a?(Hash)
    assert_equal '-1M', res['added']
    assert_equal 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX', res['license']
    assert_equal 1308066592, res['time']
    assert_equal -50.0, res['bal']
    assert_equal 'refund', res['action']
    assert_equal '2.00', res['rate']
    assert_equal 99999, res['actid']
    assert_equal 'XXXXX', res['lid']
    assert_equal -2.0, res['amt']
  end

  test "#list_licenses" do
    mock_request(:list_licenses)
    res = @noc.list_licenses
    assert res.is_a?(Hash)
    assert_equal 1, res['num_results']
    assert_equal 1, res['num_active']
    assert_not_nil res['licenses']
  end

  test "#cancel_license" do
    mock_request(:cancel_license)
    assert_raise(Snuggie::Errors::MissingArgument, "requires lickey or licip") do
      @noc.cancel_license
    end
    # TODO: fixture/test
    res = @noc.cancel_license :key => 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
    assert res.is_a?(Hash)
    assert res['cancelled_license'].is_a?(Hash)
    res = res['cancelled_license']
    assert_equal '0', res['apiuid']
    assert_equal 'XXXX', res['nocid']
    assert_equal '1', res['servertype']
    assert_equal 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX', res['license']
    assert_equal '1308062889', res['time']
    assert_equal '20110614', res['expires']
    assert_equal '1', res['type']
    assert_equal '0', res['last_sync']
    assert_equal 'marty@hilldale.edu', res['authemail']
  end

  test "#invoice_details unbilled" do
    mock_request(:invoice_details_unbilled)
    res = @noc.invoice_details
    assert res.is_a?(Hash)
    assert res['actions'].is_a?(Hash)
    act = res['actions'][0]
    assert_equal '1M', act['added']
    assert_equal 'XXXX', act['nocid']
    assert_equal 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX', act['license']
    assert_equal '0', act['refunded']
    assert_equal '1308062889', act['time']
    assert_equal '20110614', act['date']
    assert_equal '2.00', act['rate']
    assert_equal 'new', act['action']
    assert_equal 'XXXXX', act['actid']
    assert_equal '0', act['invoid']
    assert_equal 'XXXXX', act['lid']
    assert_equal '2.00', act['amt']
  end

  test "#license_logs" do
    mock_request(:license_logs)
    assert_raise(Snuggie::Errors::MissingArgument, "requires key") do
      @noc.license_logs
    end
    res = @noc.license_logs :key => 'XXXXX-XXXXX-XXXXX-XXXXX'

    assert res.is_a?(Hash)
    assert res['actions'].is_a?(Array)
    act = res['actions'].first
    assert act.is_a?(Hash)
    assert_equal '1M', act['added']
    assert_equal 'XXXX', act['nocid']
    assert_equal '0', act['refunded']
    assert_equal '1308062889', act['time']
    assert_equal '20110614', act['date']
    assert_equal '2.00', act['rate']
    assert_equal 'new', act['action']
    assert_equal '0', act['invoid']
    assert_equal 'XXXXX', act['lid']
    assert_equal '2.00', act['amt']
    lic = res['license']
    assert lic.is_a?(Hash)
    assert_equal '1', lic['servertype']
    assert_equal 'XXXX', lic['nocid']
    assert_equal '0', lic['apiuid']
    assert_equal 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX', lic['license']
    assert_equal '20110714', lic['expires']
    assert_equal '1308062889', lic['time']
    assert_equal '0', lic['last_sync']
    assert_equal '1', lic['type']
    assert_equal 'XXXXX', lic['lid']
    assert_equal 'marty@hilldale.edu', lic['authemail']
    assert_equal '1', lic['active']
  end

  test "#edit_ips" do
    mock_request(:edit_ips)
    assert_raise(Snuggie::Errors::MissingArgument, "requires ips and lid") do
      @noc.edit_ips
    end
    res = @noc.edit_ips :ips => '127.0.0.2', :lid => 'XXXXX'

   assert res.is_a?(Hash)
   assert_equal 99999, res['lid']
   assert res['new_ips'].is_a?(Array)
   assert_equal '127.0.0.2', res['new_ips'].first
  end
end
