module Sheen
  class CacheObject
    include Mongoid::Document
    include Mongoid::Timestamps

    field :uri, :type => String
    field :status, :type => Integer
    field :ttl, :type => Integer, :default => 0
    field :content_type, :type => String
    field :content, :type => String

    index :uri, :unique => true, :background => true
    index :content_type, :background => true
  
    def expires_at
      created_at + ttl.seconds
    end
  end
end
