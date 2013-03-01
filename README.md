# Usage

    $ gem install rackstatic
    $ cd your_rack_app/
    $ rackstatic

A static mirror-copy of your website will now exist under `your_rack_app/build/`.

# Why?

I found it silly that static-site generators were their own category of application, with their own special libraries and requirements, completely detached from common web-development practice.

`rackstatic` fixes that. You can now develop your static websites in, say, [Sinatra](https://github.com/sinatra/sinatra). Have fun.
