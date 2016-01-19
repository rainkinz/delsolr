require 'faraday'

module DelSolr

  module Cloud

    class Connection

      def initialize(options = {})
        server = options.fetch(:server)
        port = options.fetch(:port) { 2181 }.to_i
        @timeout = options.fetch(:timeout) { "120" }
        @logger = options.fetch(:logger) { NullLogger.new }
        @zk_info = ZKInfo.new(:server => server, :port => port,
                              :logger => @logger)
      end

      def post(method, params, opts = {})
        response = begin
          opts = opts.dup.merge(:timeout => @timeout)

          node = @zk_info.node_for_collection(opts.fetch(:collection))
          url = File.join(node, method)

          # TODO: Not that familiar with faraday. Is this the best idea?
          Faraday.post(url, params, opts)
        rescue Faraday::ClientError => e
          raise Client::ConnectionError, e.message
        end

        code = response.respond_to?(:code) ? response.code : response.status
        unless (200..299).include?(code.to_i)
          raise Client::ConnectionError, "Connection failed with status: #{code}"
        end

        body = response.body

        # We get UTF-8 from Solr back, make sure the string knows about it
        # when running on Ruby >= 1.9
        if body.respond_to?(:force_encoding)
          body.force_encoding("UTF-8")
        end

        response
      end

    end
  end

end
