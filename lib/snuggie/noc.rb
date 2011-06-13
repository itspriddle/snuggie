module Snuggie
  class NOC
    API_URL = 'http://www.softaculous.com/noc'

    def initialize(credentials = {})
      credentials = {
        :username => Snuggie.config.username,
        :password => Snuggie.config.password
      } if credentials.empty? && Snuggie.config.username && Snuggie.config.password

      @required_params = [:ca]
      @credentials     = credentials
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
      require_params :purchase, :ips, :toadd, :servertype, :authemail, :autorenew
    end

    # Refund a transaction
    #
    # NOTE: A refund can only be issued within 7 days of buying/renewing
    # a license.
    #
    # Params
    #   * actid - The Action ID to clain a refund for
    # def refund(id)
    #   require_params :actid
    #   commit(:actid => id)
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
    def list_licenses(params = {})
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
    def require_params(*args)
      args.flatten.each do |arg|
        @required_params << arg unless @required_params.include?(arg)
      end
    end

    def query_string(params = {})
      if missing = missing_params(params)
        raise "Missing parameters: #{missing.join(', ')}"
      end
    end

    def missing_params(params = {})
      missing = []
      @required_params.each do |param|
        missing << param unless params.has_key?(param)
      end
      missing.empty? ? nil : missing
    end
  end
end
