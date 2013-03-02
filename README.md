# Introduction

There's this category of web framework called "static-site generators", or "SSGs" for short. We, as developers, use them because it's easier than the alternative: writing a regular server, then launching it, mirroring the contents using some arcane `wget` incantation, and shutting it back down afterward.

But while SSGs eliminate *this* particular hassle, they come with their own: they require you to organize everything their own persnickety way; they don't follow common web-development practices; you have to write special plugins for them if you want to use any templating library or database adapter or whatever else that would "just work" anywhere else. It's almost less work to use `wget`.

`rackstatic` cuts this Gordian knot. Using `rackstatic`, you can develop your static website in, say, [Sinatra](https://github.com/sinatra/sinatra). Or any Rack-compatible web framework (yes, even Rails, if you really really want.) And it's just as easy as using an SSG.

## Here's the deal:

    $ gem install rackstatic
    $ cd your_rack_app/
    $ rackstatic dist/

A static mirror-copy of your website will now exist under `your_rack_app/dist/`.

If your repo is layed out such that your application files (`config.ru` et al) exist under `your_repo/app/`, you can build from above it to keep things clean and separate:

    $ gem install rackstatic
    $ cd your_repo/
    $ rackstatic dist/

This will use the app in `your_repo/app/` to build `your_repo/dist/`.

## How does it work?

`rackstatic` uses the mock Rack session functionality of [rack-test](https://github.com/brynary/rack-test). Except, not so much for testing :grinning:. Instead, the values returned in each request are written to disk, then spidered (using [nokogiri](https://github.com/sparklemotion/nokogiri) to find more URLs to request.

## What about static files?

Some files aren't linked anywhere: `robots.txt`, `crossdomain.xml`, `favicon.ico`, and so forth. A regular spidering-based mirroring process would miss these.

To prevent this, `rackstatic` will attempt to request anything it sees under `your_rack_app/public/` (e.g. `your_rack_app/public/robots.txt` -> `GET /robots.txt`), as if they had been linked to. You can change what subdirectory of your app is looked under using the `-s` switch:

    $ rackstatic -s static/ dist/

## It's probably better to...

add `rackstatic` to your Gemfile. Then, when you pull down your app from its repo, it's as simple as:

    $ bundle install
    $ bundle exec rackstatic dist/

## Programmatic usage

You can add a deploy task to your Rakefile that calls `rackstatic`. Rather than messing with shell commands, try this:

    task :deploy do
      require 'rack/static-builder'
      Rack::StaticBuilder.new(:app_dir => 'app/', :dest_dir => 'dist/').build!

      # now push dist/ to S3 or Github or where-ever you like
    end

