require 'cgi'
require 'php_serialize'

module Snuggie
  class NOC
    API_URL = 'http://www.softaculous.com/noc'

    def initialize(credentials = {})
      credentials = {
        :username => Snuggie.config.username,
        :password => Snuggie.config.password
      } if credentials.empty? && Snuggie.config.username && Snuggie.config.password

      @credentials = credentials
    end

    # Buy a license
    #
    # Params
    #   * ip         - The IP of the license to be Purchased or Renewed
    #   * toadd      - Time to extend, eg: 1M, 8M, 1Y
    #   * servertype - 1 for Dedicated and 2 for VPS
    #   * authemail  - When buying a new license, this is required to
    #                  verify the owner of the License. This address will
    #                  be used to send reminders when the license is
    #                  expiring. Not required for renewals
    #   * autorenew  - Renew this license automatically before
    #                  expiration. Set to 1 for true, 2 for false
    def buy_license(params = {})
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
    #   * actid - The Action ID to clain a refund for
    # def refund(id)
    #   commit({ :ca => :refund, :actid => id }, :require => [:actid])
    # end

    # List licenses
    #
    # NOTE: All parameters are optional. If called without parameters, a
    # list of all of your licenses will be returned.
    #
    # Params
    #   * key    - (Optional) Search for a specific License by License Key
    #   * ip     - (Optional) Search for a specific License by Primary IP
    #   * expiry - (Optional) Fetch a list of Licenses that are expiring
    #              Set to 1 to list all expired licenses on your account
    #              Set to 2 to list licenses expiring in the next 7 days
    #              Set to 3 to list licenses expiring in the next 15 days
    #   * start  - (Optional) The starting point to return from
    #              Eg: specify 99 if you have 500 licenses and want to
    #              return licenses 100-500.
    #   * len    - (Optional) The length to limit the result set to
    #              Eg: specify 100 if you have 500 licenses and want to
    #              limit the result set to 100 items
    #
    # def list_licenses(params = {})
    #   commit(params, :optional => [:key, :ip, :expiry, :start, :len])
    # end

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
    #
    # def cancel(params = {})
    # end

    # Edit IPs associated with a license
    #
    # Params
    #   * lid - The license ID (**NOT** the license key)
    #   * ips - The list of IPs of the same VPS/Server. The first IP is
    #           the Primary IP. You may add up to 8 IPs
    #
    # def edit_ips(params = {})
    # end

    # Get details for an invoice
    #
    # NOTE: If invoid is 0 or not set, a list of **all** unbilled
    # transactions for the current month will be returned
    #
    # Params
    #   * invoid - The invoice ID to getch details for.
    #
    # def invoice_details(params = {})
    # end

    # Get Action Logs for a license
    #
    # NOTE: The logs are returned in **DESCENDING ORDER**, meaning the
    # latest logs will appear first.
    #
    # Params
    #   * key   - The license key
    #   * limit - The number of action logs to return
    #
    # def license_logs(params = {})
    # end

  private
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

      uri = "#{API_URL}?#{query_string(params)}"
      if res = fetch(uri)
        @response = begin
                      PHP.unserialize(res.body)
                    rescue
                      res.body
                    end
      end
    end

    def require_params(params, keys)
      keys.each { |key| return false unless params[key] }
      true
    end

    def require_one_of(params, keys)
      keys.each { |key| return true if params[key] }
      false
    end

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
