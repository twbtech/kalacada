module Solas
  class Connection
    def self.instance
      @instance ||= new
    end

    def self.close
      @instance&.close
      @instance = nil
    end

    def initialize
      @connection = Mysql2::Client.new solas_config[:database]
    end

    def query(statement)
      Rails.logger.info "SOLAS SQL Query: #{query_label}:\n#{statement}\n\n" if Rails.env.development?
      @connection.query(statement)
    end

    def close
      @connection.close
    end

    private

    def solas_config
      unless @config
        config = YAML.safe_load(File.read(Rails.root.join('config', 'solas.yml')))
        @config = HashWithIndifferentAccess.new(config)
      end

      @config
    end

    def query_label
      index = caller.index { |c| c.match?(%r{.*/app/models/solas/base\.rb.*`query'$}) }
      method_name = caller[index - 1].scan(/block\sin\s(.*)'/).flatten.first
      class_name  = caller[index - 1].scan(%r{models/solas/(.*)\.rb}).flatten.first.camelize

      "#{class_name}::#{method_name}"
    end
  end
end
