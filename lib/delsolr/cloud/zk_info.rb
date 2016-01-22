require 'zk'
require 'json'

module DelSolr

  module Cloud

    class ZKInfo
      include MonitorMixin

      attr_reader :logger

      def initialize(opts = {})
        super()
        @logger = opts.fetch(:logger) { NullLogger.new }

        @zk = opts[:zk] || connect_to_zookeeper(opts)
        watch_live_nodes
        watch_collections
        update_urls
      end

      def update_live_nodes
        synchronize do
          @live_nodes = {}
          @zk.children("/live_nodes", watch: true).each do |node|
            @live_nodes[node] = true
          end
        end
      end

      def active_collection_names
        @active_collection_names
      end

      def live_nodes
        @live_nodes.inject([]) {|memo, (k, v)| memo << k if v; memo }
      end

      def node_for_collection(collection_name, leader_only: false)
        if leader_only
          synchronize { @leader_urls[collection_name].to_a.sample }
        else
          synchronize { @all_urls[collection_name].to_a.sample }
        end
      end

      private

       def available_urls(collection_name, collection_state)
        leader_urls = []
        all_urls = []
        all_nodes(collection_state).each do |node|
          next unless active_node?(node)
          url = "#{node['base_url']}/#{collection_name}"
          leader_urls << url if leader_node?(node)
          all_urls << url
        end
        [all_urls, leader_urls]
      end

       def all_nodes(collection_state)
        nodes = collection_state['shards'].values.map do |shard|
          shard['replicas'].values
        end
        nodes.flatten
      end

      def connect_to_zookeeper(opts ={})
        zk_url = opts.fetch(:zk_url) {
          "#{opts.fetch(:server)}:#{opts.fetch(:port)}/solr"
        }
        logger.info "Connecting to zookeeper at: '#{zk_url}'"
        ZK.new(zk_url)
      end

      def update_urls
        synchronize do
          @all_urls = {}
          @leader_urls = {}
          @collections.each do |name, state|
            @all_urls[name], @leader_urls[name] = available_urls(name, state)
          end
          update_active_collections
        end
      end

      def update_collections
        live_collections = @zk.children("/collections", watch: true)
        created = []
        synchronize do
          @collections ||= {}
          deleted = @collections.keys - live_collections
          created = live_collections - @collections.keys
          deleted.each {|coll| @collections.delete(collection) }
        end
        created.each {|coll| watch_collection(coll) }
      end

      def update_collection_state(collection)
        synchronize do
          collection_state_json, _stat =
            @zk.get(collection_state_znode_path(collection), watch: true)
          @collections.merge!(JSON.parse(collection_state_json))
        end
      end

      def update_active_collections
        @active_collection_names = @collections.inject([]) {|a, (col, state)|
          has_active_shard?(state) && a << col; a
        }
      end

      def collection_state_znode_path(collection_name)
        "/collections/#{collection_name}/state.json"
      end

      def active_node?(node)
        @live_nodes[node['node_name']] && node['state'] == 'active'
      end

      def leader_node?(node)
        node['leader'] == 'true'
      end

      def has_active_shard?(node)
        node['shards'].values.map{|s| s['state'] == 'active'}.any?
      end

      ##############
      ##  WATCHES ##
      ##############

      def watch_collections
        @zk.register("/collections") do
          update_collections
          update_urls
        end
        update_collections
      end

      def watch_live_nodes
        @zk.register("/live_nodes") do
          update_live_nodes
          update_urls
        end
        update_live_nodes
      end

      def watch_collection(collection)
        @zk.register(collection_state_znode_path(collection)) do
          update_collection_state(collection)
          update_urls
        end
        update_collection_state(collection)
      end

    end
  end
end
