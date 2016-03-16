require 'faraday'

module DelSolr

  module Cloud

    class Connection

      def initialize(options = {})
        server = options.fetch(:server)
        port = options.fetch(:port) { 2181 }.to_i
        @timeout = options.fetch(:timeout) { "120" }
        @logger = options.fetch(:logger) { NullLogger.new }
        @zk_info = options.fetch(:zk_info) {
          ZKInfo.new(:server => server, :port => port, :logger => @logger)
        }
      end

      def post(method, params, opts = {})
        response = begin

          collections = collections(opts)
          node = @zk_info.node_for_collection(collections.first)
          if node.nil?
            raise ArgumentError, "No node found for collection: #{collections.first}"
          end

          missing_collections = collections - @zk_info.active_collection_names
          unless missing_collections.empty?
            raise ArgumentError, "Trying to search of non-existent collections #{missing_collections}"
          end

          url = File.join(node, method)

          puts "#{url}?#{params}"

          # TODO: Not that familiar with faraday. Is this the best idea?
          Faraday.post(url, params, faraday_opts(opts))
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

      def faraday_opts(opts)
        faraday_opts = {}
        faraday_opts[:timeout] = opts.fetch(:timeout) { @timeout }
        faraday_opts
      end

      def collections(opts)
        collections = opts[:collections] || Array(opts[:collection])
        if collections.empty?
          raise ArgumentError, "A :collection => 'name_of_collection' or " +
            ":collections => [array_of_collection_names] is required"
        end
        collections
      end


      def xor(array1, array2)
        array1 + array2 - (array1 & array2)
      end

    end
  end

end
