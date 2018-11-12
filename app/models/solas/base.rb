module Solas
  class Base < OpenStruct
    def self.query
      yield Solas::Connection.instance
    end
  end
end
