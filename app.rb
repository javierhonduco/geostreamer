class GeoStreamer
  # TODO: reload on SIG__whatever__
  # TODO: add stats
  attr_accessor :client
  def initialize config
    @client = Twitter::Streaming::Client.new(config)
    @processor = AsyncProcessor.new
  end
  def track_location locations
    client.filter(locations: locations) do |tweet|
      process(tweet)
    end
  end
  def track_keywords keywords
    client.filter(track: keywords) do |tweet|
      process(tweet)
    end
  end

  def process tweet
    @processor.process(tweet)
  end
end

class AsyncProcessor
  def process tweet
    # do nothing for now
    # should insert the normalized tweet in the db
  end
end

#geo = GeoStreamer.new #credentials
#geo.track_keywords 'a, b'
