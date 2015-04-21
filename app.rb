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
    track_keywords 'a,b'
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
    @processor.process(tweet)
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

puts "pid: #{Process.pid}"

geo = GeoStreamer.new config
geo.track_keywords 'a, b'
geo.loop 0.1
geo.collect!
