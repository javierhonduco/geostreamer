require 'twitter'
require 'dotenv'
Dotenv.load

class GeoStreamer
  # TODO: reload on SIG__whatever__
  # TODO: add stats
  attr_accessor :client, :keywords_pid, :loop_pid
  def initialize config
    @client = Twitter::Streaming::Client.new(config)
    @processor = DummyAsyncProcessor.new
    Signal.trap('INT') { 
      Process.kill('TERM', @keywords_pid)
      Process.kill('TERM', @loop_pid)
      exit
    }
  end
  def track_location locations
    @locations_pid = Process.fork do
      client.filter(locations: locations) do |tweet|
        process(tweet)
      end
    end
  end
  def track_keywords keywords
    @keywords_pid = Process.fork do
      client.filter(track: keywords) do |tweet|
        process(tweet)
      end
    end
  end

  def process tweet
    @processor.process(tweet)
  end
  def loop every
    @loop_pid = Process.fork do 
      while true
        puts 'yaay'
        sleep every
      end
    end
  end
end

class DummyAsyncProcessor
  def process tweet
    # do nothing for now
    # should insert the normalized tweet in the db
    puts tweet
  end
end



config = {
  consumer_key: ENV['CONSUMER_KEY'], 
  consumer_secret: ENV['CONSUMER_SECRET'], 
  access_token: ENV['ACCESS_TOKEN'], 
  access_token_secret: ENV['ACCESS_SECRET']
}

geo = GeoStreamer.new config
geo.track_keywords 'a, b'
geo.loop 0.1

Process.wait geo.keywords_pid
Process.wait geo.loop_pid
