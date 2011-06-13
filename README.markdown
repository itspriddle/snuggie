# Snuggie [![Build Status](http://travis-ci.org/site5/snuggie.png)][Build Status]

Snuggie wraps the Softaculous API in a warm, loving embrace.

[Build Status]: http://travis-ci.org/site5/snuggie

## Installation

    gem install snuggie

## Usage

Create a new `Snuggie::NOC` object with your credentials:

    noc = Snuggie::NOC.new(
      :username => 'marty',
      :password => 'mcSUPERfly'
    )

Buy/renew a license

    noc.buy_license(params = {})

Refund a transaction

    noc.refund invoice_id

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

    noc.invoice_details id

Get unbilled transactions for the current month:

    noc.invoice_details

Cancel a license by key

    noc.cancel_license :key => 'KEY'

Cancel a license by IP

    noc.cancel_license :ip => 'IP'

Get Action/Activity logs for a license

    noc.license_logs :key => 'KEY'

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version
  unintentionally.
* Commit, do not bump version. (If you want to have your own version, that is
  fine but bump version in a commit by itself I can ignore when I pull.)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Site5 LLC. See LICENSE for details.
