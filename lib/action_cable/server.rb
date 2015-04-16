module ActionCable
  class Server
    PUBSUB_PING_TIMEOUT = 120

    cattr_accessor(:logger, instance_reader: true) { Rails.logger }

    attr_accessor :registered_channels, :redis_config

    def initialize(redis_config:, channels:, worker_pool_size: 100, connection: Connection)
      @redis_config = redis_config.with_indifferent_access
      @registered_channels = Set.new(channels)
      @worker_pool_size = worker_pool_size
      @connection_class = connection

      @connections = []

      logger.info "[ActionCable] Initialized server (redis_config: #{@redis_config.inspect}, worker_pool_size: #{@worker_pool_size})"
    end

    def call(env)
      @connection_class.new(self, env).process
    end

    def worker_pool
      @worker_pool ||= ActionCable::Worker.pool(size: @worker_pool_size)
    end

    def pubsub
      @pubsub ||= redis.pubsub.tap { |pb| add_pubsub_periodic_timer(pb) }
    end

    def redis
      @redis ||= begin
        redis = EM::Hiredis.connect(@redis_config[:url])
        redis.on(:reconnected) do
          logger.info "[ActionCable] Redis reconnected."
          # logger.info "[ActionCable] Redis reconnected. Closing all the open connections."
          # @connections.map &:close_connection
        end
        redis
      end
    end

    def threaded_redis
      @threaded_redis ||= Redis.new(redis_config)
    end

    def remote_connections
      @remote_connections ||= RemoteConnections.new(self)
    end

    def broadcaster_for(channel)
      Broadcaster.new(self, channel)
    end

    def broadcast(channel, message)
      broadcaster_for(channel).broadcast(message)
    end

    def connection_identifiers
      @connection_class.identifiers
    end

    def add_connection(connection)
      @connections << connection
    end

    def remove_connection(connection)
      @connections.delete connection
    end

    def open_connections_statistics
      @connections.map(&:statistics)
    end

    protected
      def add_pubsub_periodic_timer(ps)
        @pubsub_periodic_timer ||= EventMachine.add_periodic_timer(PUBSUB_PING_TIMEOUT) do
          logger.info "[ActionCable] Pubsub ping"
          ps.ping
        end
      end
  end
end
