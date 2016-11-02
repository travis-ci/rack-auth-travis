# Rack::Auth::Travis

:warning: **This middleware does not work with the public hosted Travis CI
anymore** :warning:

For more details, see [this blog
post](https://blog.travis-ci.com/2016-08-31-webhook-delivery-changes).

It's a Rack auth thing for Travis webhook requests!

## Install

Depend on it!

``` ruby
# Gemfile
gem 'rack-auth-travis'
```

## Usage

Add it to your rack!

Take a look at the [example](./example) or do something like this:

``` ruby
# config.ru
require './my_fancy_app'
require 'rack-auth-travis'

use Rack::Auth::Travis
run MyFancyApp.new
```

When `use`'d without arguments, `Rack::Auth::Travis` will add an `ENV`-based
authenticator that will look for the following variables and use their values to
authenticate the `Authorization` header:

- `TRAVIS_AUTH_<uppercased-slug>` - generated from the "repo slug" with
  non-alphanumeric characters replaced with underscores, e.g.
  `octocat/Knife-Spoon` becomes `TRAVIS_AUTH_OCTOCAT_KNIFE_SPOON`
- `TRAVIS_AUTH_DEFAULT`

If one of these `ENV` variables exists, its value will be hashed with the "repo
slug" and compared to the `Authorization` header sent from Travis.
