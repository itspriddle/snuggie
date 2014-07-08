# Snuggie [![Snuggie Build Status][Build Icon]][Build Status]

Snuggie wraps the Softaculous API in a warm, loving ruby embrace.

Snuggie has been tested on MRI 1.9.3, MRI 2.0.0, MRI 2.1.2, 1.9-compatible JRuby.

[Build Status]: http://travis-ci.org/site5/snuggie
[Build Icon]: https://secure.travis-ci.org/site5/snuggie.png?branch=master

## Installation

    gem install snuggie

## Usage

Create a new `Snuggie::NOC` object with your credentials:

    noc = Snuggie::NOC.new(
      :username => 'marty',
      :password => 'mcSUPERfly'
    )

Your Softaculous credentials can also be configured globally:

    Snuggie.configure do |config|
      config.username = 'marty'
      config.password = 'mcSUPERfly'
    end

    noc = Snuggie::NOC.new

Buy/renew a license

    noc.buy_license(
      :ip            => '127.0.0.1',
      :months_to_add => 1,
      :server_type   => :dedicated,
      :auth_email    => 'marty@hilldale.edu',
      :auto_renew    => true
    )

Refund a transaction

    noc.refund :action_id => 99999

List all licenses

    noc.list_licenses

List licenses by IP

    noc.list_licenses :ip => '127.0.0.1'

List all expired licenses

    noc.list_licenses :expired => 1

List licenses expiring in 7 days

    noc.list_licenses :expired => 2

List licenses expiring in 15 days

    noc.list_licenses :expired => 3

Get invoice details

    noc.invoice_details :invoice_id => 99999

Get unbilled transactions for the current month:

    noc.invoice_details

Cancel a license by key

    noc.cancel_license :key => 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'

Cancel a license by IP

    noc.cancel_license :ip => '127.0.0.1'

Get Action/Activity logs for a license

    noc.license_logs :key => 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version
  unintentionally.
* Commit, do not bump version. (If you want to have your own version, that is
  fine but bump version in a commit by itself I can ignore when I pull.)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2012-2014 Site5.com. See LICENSE for details.
