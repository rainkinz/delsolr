require 'faraday'

module DelSolr

  class Client

    class DirectConnection

      def initialize(options = {}, &connection_block)
        @server = options.fetch(:server)
        @port = options.fetch(:port).to_i
        @timeout = options.fetch(:timeout) { "120" }
        @path = options.fetch(:path) { '/solr' }
        @connection_block = connection_block
      end

      def post(method, params, opts = {})
        response = begin
          opts = opts.dup.merge(:timeout => @timeout)

          # TODO: Test the URL creation better
          query_path = File.join(@path, collection(opts), method)

          faraday.post(query_path, params)
        rescue Faraday::ClientError => e
          raise ConnectionError, e.message
        end

        code = response.respond_to?(:code) ? response.code : response.status
        unless (200..299).include?(code.to_i)
          raise ConnectionError, "Connection failed with status: #{code}"
        end

        body = response.body

        # We get UTF-8 from Solr back, make sure the string knows about it
        # when running on Ruby >= 1.9
        if body.respond_to?(:force_encoding)
          body.force_encoding("UTF-8")
        end

        response
      end

      def collection(opts)
        if collections = opts.fetch(:collections)
          Array(collections).first
        else
          opts.fetch(:collection) { '' }
        end
      end

      def full_path
        "#{self.server}:#{self.port}#{self.path}"
      end

      def faraday
        @faraday ||= Faraday.new(:url => "http://#{@server}:#{@port}",
                                &connection_block)
      end

      def connection_block
        @connection_block ||= lambda do |faraday|
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end

end
