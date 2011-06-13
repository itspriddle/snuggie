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

  test "#commit requires all :required params" do
    assert_raise(Snuggie::Errors::MissingArgument) do
      @noc.instance_eval do
        commit({}, :required => [:fuel])
      end
    end

    assert_nothing_raised do
      @noc.instance_eval do
        commit({ :fuel => :plutonium }, :required => [:fuel])
      end
    end
  end

  test "#commit requires one of :require_one params" do
    assert_raise(Snuggie::Errors::MissingArgument) do
      @noc.instance_eval do
        commit({ :date => 1955 }, :require_one => [:fuel])
      end
    end

    assert_nothing_raised do
      @noc.instance_eval do
        commit({ :fuel => :plutonium, :date => 1955 }, :require_one => [:fuel])
      end
    end
  end

  # test "#buy_license required params" do
  #   assert_required_params @noc, :buy_license, :ca, :purchase, :ips, :toadd, :servertype, :authemail, :autorenew
  # end

  # test "#list_licenses has no required params" do
  #   assert_no_required_params @noc, :list_licenses
  # end
end
