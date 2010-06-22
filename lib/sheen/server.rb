module Sheen
  class Request
    attr_accessor :method, :headers, :uri, :query_string

    def initialize(attributes = {})
      @method = attributes[:method]
      @headers = attributes[:headers]
      @uri = attributes[:uri]
      @query_string = attributes[:query_string]

      unless @query_string.blank?
        @uri += "?#{@query_string}"
      end
    end
  end

  module Server
    include EventMachine::HttpServer

    attr_accessor :hit, :pass, :request, :response
  
    def process_http_request
      @request = Request.new(
        :method => @http_method,
        :headers => @http_headers,
        :uri => @http_request_uri,
        :query_string => @http_query_string)

      @response = EventMachine::DelegatedHttpResponse.new(self)

      @cache_object = Sheen::CacheObject.where(:uri => @request.uri).first
      @hit = (@cache_object.nil? || @cache_object.expires_at < Time.now) ? false : true

      receive
    end

    def lookup
      if @hit
        populate_response(@cache_object)
        deliver
        @response.send_response
      else
        http = EventMachine::Protocols::HttpClient.request(
          :host => backends.first[:host],
          :port => backends.first[:port],
          :request => @request.uri)
  
        http.callback do |r|
          headers = headers_as_hash(r[:headers])
  
          @cache_object = Sheen::CacheObject.find_or_create_by(:uri => @request.uri)
          @cache_object.ttl = headers['Cache-Control'].match(/(\d+)/)[0].to_i.seconds
          @cache_object.status = r[:status]
          @cache_object.content_type = headers['Content-Type'].split(';').first
          @cache_object.content = r[:content]
          @cache_object.save

          populate_response(@cache_object)

          fetched
          deliver
          @response.send_response
        end
      end
    end
  
  private

    def headers_as_hash(headers)
      returning hash = {} do
        headers.shift
        headers.each do |header|
          k,v = header.split(':')
          hash[k.strip] = v.strip
        end
      end
    end

    def populate_response(cache_object)
      @response.status = cache_object.status
      @response.content_type(cache_object.content_type)
      @response.content = cache_object.content
    end
  end
end
