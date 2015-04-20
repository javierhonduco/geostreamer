client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = 'YOUR_CONSUMER_KEY'
  config.consumer_secret     = 'YOUR_CONSUMER_SECRET'
  config.access_token        = 'YOUR_ACCESS_TOKEN'
  config.access_token_secret = 'YOUR_ACCESS_SECRET'
end

# in another process
client.filter(locations: '-122.75,36.8,-121.75,37.8') do |tweet|
  puts tweet.text
end

# in other process
# on SIG__whatever__, reload with new keywords data
client.filter(track: 'sexy, keywords, are, sexy') do |tweet|
  puts tweet.text
end

# on every tweet, send to queue
# move from queue to postgis 
# profit!
