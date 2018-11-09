module Solas
  class Base < OpenStruct
    def self.query
      connection = Solas::Connection.new
      yield connection
    ensure
      connection.close
    end
  end
end
