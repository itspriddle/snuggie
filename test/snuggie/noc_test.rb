require 'test_helper'

context "Snuggie::NOC" do
  @@credentials = { :username => 'marty', :password => 'mcSUPERfly' }

  setup do
    @noc = Snuggie::NOC.new(@@credentials)
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
        commit({}, :require => [:fuel])
      end
    end

    params = { :fuel => :plutonium }
    mock_request(mock_query_url(params))
    assert_nothing_raised do
      @noc.instance_eval do
        commit(params, :require => [:fuel])
      end
    end
  end

  test "#commit requires one of :require_one params" do
    p1 = { :date => 1955 }
    mock_request(mock_query_url(p1))
    assert_raise(Snuggie::Errors::MissingArgument) do
      @noc.instance_eval do
        commit(p1, :require_one => [:fuel])
      end
    end

    p2 = { :date => 1955, :fuel => :plutonium }
    mock_request(mock_query_url(p2))
    assert_nothing_raised do
      @noc.instance_eval do
        commit(p2, :require_one => [:fuel])
      end
    end
  end

  test "#commit returns a hash if PHP.unserialize works" do
    p1 = { :date => 1955 }
    mock_request(mock_query_url(p1), :body => PHP.serialize(:status => :success))
    res = @noc.instance_eval do
      commit(p1, :require => [:date])
    end
    assert res.has_key? 'status'
    assert res['status'] == 'success'
  end

  test "#commit returns HTTP body if PHP.unserialize fails" do
    p1 = { :date => 1955 }
    mock_request(mock_query_url(p1), :body => "not a PHP serialized string")
    res = @noc.instance_eval do
      commit(p1, :require => [:date])
    end
    assert_equal res, 'not a PHP serialized string'
  end

  test "#buy_license required params" do
    keys = [:purchase, :ips, :toadd, :servertype, :authemail, :autorenew]
    assert_raise(Snuggie::Errors::MissingArgument, "requires args") do
      @noc.buy_license
    end
  end

  # test "#refund" do
  #   assert_raise(ArgumentError, "required ip") do
  #     @noc.refund
  #   end
  # end

  # test "#list_licenses" do
  #   assert_nothing_raised do
  #     @noc.list_licenses
  #   end
  # end

end
