require 'uri'
require 'pathname'

require 'rack'
require 'rack/test'
require 'nokogiri'

class Rack::StaticBuilder
  VERSION = '0.1.4'

  class BuildError < Exception; end

  class RequestPathQueue
    def initialize
      @active = nil
      @queue = ['/']
      @seen = {}
    end

    def enqueue(url)
      path = URI.parse(url).path

      # discard URNs like data: and magnet:
      return false unless path

      if path[0] != '/'
        path = URI.parse( (@active || '/').sub(/\/[^\/]*$/, '') + '/' + path ).path
      end

      @queue << path
    end
    alias_method :'<<', :enqueue

    def drain
      while path = @queue.shift
        @seen[path] ||= (yield(path); true)
      end
    end
  end


  def initialize(opts)
    opts = opts.dup

    @app_dir = [opts.delete(:app_dir), 'app', '.'].compact.find{ |d| File.file?(d + '/config.ru') }
    raise ArgumentError unless @app_dir

    @app_dir = Pathname.new(@app_dir).expand_path.cleanpath
    @dest_dir = Pathname.new(opts.delete(:dest_dir) || 'dist').expand_path.cleanpath
    @app_static_dir = (@app_dir + (opts.delete(:static_dir) || 'public')).expand_path.cleanpath

    @noise_level = (opts.delete(:noise_level) || '0').to_i
    @preserve_on_error = opts.delete(:preserve_on_error)
  end

  def build
    @dest_dir.rmtree if @dest_dir.directory?

    queue = RequestPathQueue.new

    enqueue_static_assets(queue)

    req_stats = {
      :status => Hash.new(0),
      :category => Hash.new(0),
      :succeeded => 0,
      :failed => 0,
      :total => 0
    }

    with_rack_client do |client|

      queue.drain do |req_path|
        resp = client.get req_path

        req_status = resp.status
        req_category = (req_status / 100)
        req_succeeded = (req_category == 2)

        req_stats[:status][req_status] += 1
        req_stats[:category][req_category] += 1
        req_stats[(req_succeeded ? :succeeded : :failed)] += 1
        req_stats[:total] += 1

        if @noise_level > 1 or (!req_succeeded and @noise_level > 0)
          channel = req_succeeded ? $stdout : $stderr
          channel.puts("#{req_status} #{req_path}")
        end

        next unless req_succeeded
        next unless store_response!(req_path, resp.body)

        if enqueue_links = capture_method_for(resp.content_type)
          enqueue_links.call(queue, resp.body)
        end
      end

    end

    if req_stats[:failed] > 0 and not @preserve_on_error
      @dest_dir.rmtree if @dest_dir.directory?
    end

    req_stats
  end

  def build!
    req_stats = self.build

    raise BuildError, "#{ req_stats[:failed] } URLs requested with non-2XX responses" unless (req_stats[:failed] == 0)

    req_stats
  end


  private

  def enqueue_static_assets(queue)
    return unless @app_static_dir.directory?

    Dir.chdir(@app_static_dir) do
      Dir['**/*'].each do |f|
        next if File.directory?(f)
        queue << f
      end
    end
  end

  def with_rack_client
    Dir.chdir(@app_dir) do
      rack_app = Rack::Builder.parse_file('config.ru').first
      sess = Rack::Test::Session.new(Rack::MockSession.new(rack_app))

      yield(sess)
    end
  end

  def store_path_for(req_path)
    store_path = req_path
    store_path += 'index.html' if store_path =~ /\/$/
    store_path = @dest_dir + store_path.sub(/^\/+/, '')
  end


  def capture_method_for(content_type_str)
    m_name = ('capture_links_in_' + content_type_str.split(';', 2).first.gsub(/\//, '_').downcase).intern
    method(m_name) if self.private_methods.include?(m_name)
  end

  def capture_links_in_text_html(queue, doc_str)
    doc = Nokogiri::HTML(doc_str)

    %w(a link frame iframe script img embed audio video).each do |tag_name|
      doc.css(tag_name).each do |tag|
        next unless attr = (tag.attributes["src"] || tag.attributes["href"])
        next if attr.value =~ /^(\w+:)?\/\//
        queue << attr.value
      end
    end

    doc.css('script').each do |script|
      capture_links_in_text_javascript(queue, script.content)
    end

    doc.css('style').each do |stylesheet|
      capture_links_in_text_css(queue, stylesheet.content)
    end
  end

  def capture_links_in_text_javascript(queue, doc_str)
    # ?
  end

  def capture_links_in_text_css(queue, doc_str)
    doc_str.scan(/url\((.+?)\)/).each do |(rel_url)|
      queue << rel_url
    end
  end

  def store_response!(req_path, resp_body)
    store_path = store_path_for(req_path)

    return false if store_path.exist?

    store_path.parent.mkpath
    store_path.open('w'){ |f| f.write(resp_body) }

    true
  end
end
