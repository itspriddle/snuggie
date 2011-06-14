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

    Snuggie.configure do |c|
      c.username = nil
      c.password = nil
    end
    assert_equal Hash.new, @noc.class.new.instance_variable_get(:@credentials)
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

    assert query.match(/date=1955/)
    assert query.match(/fuel=plutonium/)
    assert query.match(/nocname=marty/)
    assert query.match(/nocpass=mcSUPERfly/)
    assert_nil query.match(/username/)
    assert_nil query.match(/password/)
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
    assert res.has_key? 'status'
    assert res['status'] == 'success'
  end

  test "#commit returns HTTP body if PHP.unserialize fails" do
    p1 = { :date => 1955 }
    mock_request(mock_query_url(p1), :body => "not a PHP serialized string")
    res = @noc.instance_eval do
      commit(p1, :require => :date)
    end
    assert_equal res, 'not a PHP serialized string'
  end

  test "#buy_license required params" do
    params = {
      :ip         => '127.0.0.1',
      :toadd      => '1M',
      :servertype => 1,
      :authemail  => 'marty@hilldale.org',
      :autorenew  => '1'
    }
    mock_request(:buy_license)
    assert_raise(Snuggie::Errors::MissingArgument, "requires args") do
      @noc.buy_license
    end

    res = @noc.buy_license(params)
    assert res.is_a?(Hash)
    assert_equal res['added'].to_i, 1
    assert_equal res['autorenew'], 'YES'
    assert_equal res['license'], 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
    assert_equal res['time'].to_i, 1308062889
    assert_equal res['bal'], -48.0
    assert_equal res['rate'].to_i, 2
    assert_equal res['actid'].to_i, 99999
    assert_equal res['ip'], '127.0.0.1'
    assert_equal res['lid'].to_i, 99999
    assert_equal res['amt'].to_i, 2
  end

  test "#refund" do
    mock_request(:refund)
    assert_raise(Snuggie::Errors::MissingArgument, "requires actid") do
      @noc.refund
    end

    res = @noc.refund :actid => 99999
    assert res.is_a?(Hash)
    assert_equal res['added'], '-1M'
    assert_equal res['license'], 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
    assert_equal res['time'], 1308066592
    assert_equal res['bal'], -50.0
    assert_equal res['action'], 'refund'
    assert_equal res['rate'], '2.00'
    assert_equal res['actid'], 0
    assert_equal res['lid'], 'XXXXX'
    assert_equal res['amt'], -2.0
  end

  test "#list_licenses" do
    mock_request(:list_licenses)
    res = @noc.list_licenses
    assert res.is_a?(Hash)
    assert_equal res['num_results'], 1
    assert_equal res['num_active'], 1
    assert_not_nil res['licenses']
  end

  test "#cancel" do
    mock_request(:cancel)
    assert_raise(Snuggie::Errors::MissingArgument, "requires lickey or licip") do
      @noc.cancel
    end
    # TODO: fixture/test
  end

  test "#invoice_details unbilled" do
    mock_request(:invoice_details_unbilled)
    res = @noc.invoice_details
    assert res.is_a?(Hash)
    assert res['actions'].is_a?(Hash)
    act = res['actions'][0]
    assert_equal act['added'], '1M'
    assert_equal act['nocid'], 'XXXX'
    assert_equal act['license'], 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
    assert_equal act['refunded'].to_i, 0
    assert_equal act['time'], '1308062889'
    assert_equal act['date'], '20110614'
    assert_equal act['rate'], '2.00'
    assert_equal act['action'], 'new'
    assert_equal act['actid'], 'XXXXX'
    assert_equal act['invoid'].to_i, 0
    assert_equal act['lid'], 'XXXXX'
    assert_equal act['amt'], '2.00'
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
    assert_equal act['added'], '1M'
    assert_equal act['nocid'], 'XXXX'
    assert_equal act['refunded'].to_i, 0
    assert_equal act['time'].to_i, 1308062889
    assert_equal act['date'].to_i, 20110614
    assert_equal act['rate'], '2.00'
    assert_equal act['action'], 'new'
    assert_equal act['invoid'].to_i, 0
    assert_equal act['lid'], 'XXXXX'
    assert_equal act['amt'], '2.00'
    lic = res['license']
    assert lic.is_a?(Hash)
    assert_equal lic['servertype'].to_i, 1
    assert_equal lic['nocid'], 'XXXX'
    assert_equal lic['apiuid'].to_i, 0
    assert_equal lic['license'], 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
    assert_equal lic['expires'].to_i, 20110714
    assert_equal lic['time'].to_i, 1308062889
    assert_equal lic['last_sync'].to_i, 0
    assert_equal lic['type'].to_i, 1
    assert_equal lic['lid'], 'XXXXX'
    assert_equal lic['authemail'], 'marty@hilldale.edu'
    assert_equal lic['active'].to_i, 1
  end

end
