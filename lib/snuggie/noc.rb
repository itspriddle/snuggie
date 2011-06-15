require 'cgi'
require 'net/http'
require 'php_serialize'

module Snuggie
  # Snuggie::NOC is the main class for communicating with the
  # Softaculous NOC API.
  class NOC

    # The Softaculous NOC API lives here
    API_URL = 'http://www.softaculous.com/noc'

    # Creates a new Snuggie::NOC instance
    #
    # Params
    #
    #   * credentials - (Optional) a hash with :username, :password to
    #                   be used to authenticate with Softaculous. If not
    #                   provided, the Snuggie will try using those
    #                   configured via `Snuggie#configure`
    def initialize(credentials = {})
      credentials = {
        :username => Snuggie.config.username,
        :password => Snuggie.config.password
      } if credentials.empty? && Snuggie.config.username && Snuggie.config.password

      @credentials = credentials
    end

    # Buy a license
    #
    # NOTE: You must specify either months_to_add or years_to_add
    #
    # Params
    #
    #   * ip             - The IP of the license to be Purchased or Renewed
    #   * months_to_add  - Months to buy/renew the license for
    #   * years_to_add   - Years to buy/renew the license for
    #   * server_type    - Type of server used by this license, should be
    #                      :dedicated or :vps
    #   * auth_email     - When buying a new license, this is required to
    #                      verify the owner of the License. This address will
    #                      be used to send reminders when the license is
    #                      expiring. Not required for renewals
    #   * auto_renew     - Renew this license automatically before
    #                      expiration. Set to true or false.
    def buy_license(params = {})
      if params[:months_to_add]
        params[:toadd] = "#{params.delete(:months_to_add)}M"
      elsif params[:years_to_add]
        params[:toadd] = "#{params.delete(:years_to_add)}Y"
      end

      if [:dedicated, :vps].include?(params[:servertype])
        params[:servertype] = params[:servertype] == :dedicated ? 1 : 2
      end
      if params.has_key?(:autorenew)
        params[:autorenew] = params[:autorenew] === true ? 1 : 2
      end

      params[:ips]        = params.delete(:ip)          if params[:ip]
      params[:autorenew]  = params.delete(:auto_renew)  if params[:auto_renew]
      params[:authemail]  = params.delete(:auth_email)  if params[:auth_email]
      params[:servertype] = params.delete(:server_type) if params[:server_type]

      params.merge!(:ca => :buy, :purchase => 1)

      commit(params,
        :require  => [:purchase, :ips, :toadd, :servertype, :autorenew]
      )
    end

    # Refund a transaction
    #
    # NOTE: A refund can only be issued within 7 days of buying/renewing
    # a license.
    #
    # Params
    #
    #   * action_id - The Action ID to clain a refund for
    def refund(params = {})
      params[:actid] = params.delete(:action_id) if params[:action_id]
      params[:ca]    = :refund
      commit(params, :require => [:actid])
    end

    # List licenses
    #
    # NOTE: All parameters are optional. If called without parameters, a
    # list of all of your licenses will be returned.
    #
    # Params
    #
    #   * key    - (Optional) Search for a specific License by License Key
    #   * ip     - (Optional) Search for a specific License by Primary IP
    #   * expiry - (Optional) Fetch a list of Licenses that are expiring
    #              Set to 1 to list all expired licenses on your account
    #              Set to 2 to list licenses expiring in the next 7 days
    #              Set to 3 to list licenses expiring in the next 15 days
    #   * start  - (Optional) The starting point to return from
    #              Eg: specify 99 if you have 500 licenses and want to
    #              return licenses 100-500.
    #   * limit  - (Optional) The length to limit the result set to
    #              Eg: specify 100 if you have 500 licenses and want to
    #              limit the result set to 100 items
    def list_licenses(params = {})
      params[:len] = params.delete(:limit) if params[:limit]
      params[:ca]  = :licenses
      commit(params)
    end

    # Cancel license
    #
    # NOTES:
    # * Either ip or key needs to be specified
    # * Cancellations are not allowed on licenses expiring more than 1
    #   month in the future.
    # * A refund is **NOT** applied when you cancel a license. You must
    #   claim the refund using Snuggie::NOC#refund
    #
    # Params
    #
    #   * key - (Optional) The license key
    #   * ip  - (Optional) The Primary IP of the license
    def cancel_license(params = {})
      params[:lickey] = params.delete(:key) if params[:key]
      params[:licip]  = params.delete(:ip)  if params[:ip]
      params.merge!(:ca => :cancel, :cancel_license => 1)
      commit(params, :require_one => [:lickey, :licip])
    end

    # Edit IPs associated with a license
    #
    # Params
    #
    #   * license_id - The license ID (**NOT** the license key)
    #   * ips        - The list of IPs of the same VPS/Server. The first IP is
    #                  the Primary IP. You may add up to 8 IPs
    def edit_ips(params = {})
      params[:'ips[]'] = params.delete(:ips)
      params[:lid]     = params.delete(:license_id) if params[:license_id]
      params.merge!(:ca => :showlicense, :editlicense => 1)
      commit(params, :require => [:lid, :'ips[]'])
    end

    # Get details for an invoice
    #
    # NOTE: If invoid is 0 or not set, a list of **all** unbilled
    # transactions for the current month will be returned
    #
    # Params
    #
    #   * invoice_id - The invoice ID to getch details for.
    def invoice_details(params = {})
      params[:invoid] = params.delete(:invoice_id) if params[:invoice_id]
      params[:ca]     = :invoicedetails
      commit(params)
    end

    # Get Action Logs for a license
    #
    # NOTE: The logs are returned in **DESCENDING ORDER**, meaning the
    # latest logs will appear first.
    #
    # Params
    #
    #   * key   - The license key
    #   * limit - The number of action logs to return
    def license_logs(params = {})
      params[:ca] = :licenselogs
      commit(params, :require => :key)
    end

  private

    # Send a request upstream to Softaculous
    #
    # Params
    #
    #   * params  - a hash of parameters for the request
    #   * options - a hash of options, used to validate required params
    def commit(params, options = {})
      if options[:require]
        unless require_params(params, options[:require])
          raise Errors::MissingArgument
        end
      end

      if options[:require_one]
        unless require_one_of(params, options[:require_one])
          raise Errors::MissingArgument
        end
      end

      params.merge!(@credentials) unless @credentials.nil? || @credentials.empty?

      uri = "#{API_URL}?#{query_string(params)}"
      if res = fetch(uri)
        @response = begin
                      PHP.unserialize(res.body)
                    rescue
                      res.body
                    end
      end
    end

    # Returns true if params has all of the specified keys
    #
    # Params
    #
    #   * params - hash of query parameters
    #   * keys   - keys to search for in params
    def require_params(params, keys)
      Array(keys).each { |key| return false unless params[key] }
      true
    end

    # Returns true if params has one of the specified keys
    #
    # Params
    #
    #   * params - hash of query parameters
    #   * keys   - keys to search for in params
    def require_one_of(params, keys)
      Array(keys).each { |key| return true if params[key] }
      false
    end

    # Formats params into a query string for a GET request
    #
    # NOTE: For convenience, this converts the keys :username and
    #       :password to :nocname and :nocpass respectively.
    #
    # Params
    #
    #   * params - hash of query parameters
    def query_string(params)
      params.map do |key, val|
        case key.to_sym
        when :username
          key = :nocname
        when :password
          key = :nocpass
        end
        "#{key}=#{CGI.escape(val.to_s)}"
      end.join('&')
    end

    # Performs a GET request on the given URI, redirects if needed
    #
    # See Following Redirection at
    # http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/classes/Net/HTTP.html
    #
    # Params
    #
    #   * uri_str - the URL to fetch as a string
    #   * limit   - number of redirects to allow
    def fetch(uri_str, limit = 10)
      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      uri = URI.parse(uri_str)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.start { |http| http.request(request) }

      case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      else
        response.error!
      end
    end
  end
end
