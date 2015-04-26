require 'twitter'
require 'dotenv'
require 'net/http'
require 'sidekiq'

Dotenv.load

class GeoStreamer
  # TODO: add stats
  attr_accessor :client

  def initialize config
    @client = Twitter::Streaming::Client.new(config)
    @processor = DummyAsyncProcessor
    @pids = []

    Signal.trap('INT') { 
      @pids.each do |pid|
        Process.kill('TERM', pid)
        @pids.shift
      end
      exit
    }

    Signal.trap('HUP') { 
      Thread.new{
        reeschedule!
      }
    }
  end
  
  def reeschedule!
    @pids.each do |pid|
      puts "reescheduling #{pid}"
      Process.kill('TERM', pid)
      @pids.shift
    end
    track_keywords 'justin,bieber'
  end

  def track_location locations
    @pids << Process.fork do
      client.filter(locations: locations) do |tweet|
        process(tweet)
      end
    end
  end

  def track_keywords keywords
    @pids << Process.fork do
      client.filter(track: keywords) do |tweet|
        process(tweet)
      end
    end
  end

  def process tweet
    lat, long = tweet.geo.lat, tweet.geo.long
    @processor.perform_async(tweet.text.to_s, lat, long) unless lat.nil? || long.nil?
  end

  def loop every
    @pids << Process.fork do 
      while true
        puts 'yaay'
        sleep every
      end
    end
  end

  def collect!
    @pids.each do |pid|
      Process.wait(pid)
    end
  end
end

class DummyAsyncProcessor
  include Sidekiq::Worker
  
  def perform tweet, lat, long
    sql = "INSERT INTO untitled_table_1(the_geom, description, name) VALUES (ST_SetSRID(ST_Point(#{lat}, #{long}), 4326), '#{tweet}', '')"

    cartodb_api = URI.escape "https://#{ENV['CARTODB_ACCOUNT']}.cartodb.com/api/v2/sql?q=#{sql}&api_key=#{ENV['CARTODB_API_KEY']}"
    Net::HTTP.get(URI.parse(cartodb_api))

    puts 'Sent! :)'
  end
end


config = {
  consumer_key: ENV['CONSUMER_KEY'], 
  consumer_secret: ENV['CONSUMER_SECRET'], 
  access_token: ENV['ACCESS_TOKEN'], 
  access_token_secret: ENV['ACCESS_SECRET']
}

Sidekiq.configure_client do |config|
  config.redis = {:namespace => 'untitled_ns'}
end

if __FILE__ == $0
  puts "pid: #{Process.pid}"

  geo = GeoStreamer.new config
  geo.track_keywords 'a, b'
  #geo.loop 0.1
  geo.collect!
end
