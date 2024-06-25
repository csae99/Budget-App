# config/initializers/redis.rb

require 'redis'

# Helper method to connect to Redis instance
def connect_redis(env_var, default_url, name)
  redis_url = ENV[env_var] || default_url
  begin
    Redis.new(url: redis_url)
  rescue => e
    Rails.logger.error("Failed to connect to #{name}: #{e.message}")
    raise e
  end
end

# Check if the application is precompiling assets
if ENV['RAILS_ENV'] == 'assets'
  puts "Skipping Redis connection during asset precompilation."
else
  # Initialize Redis connections
  $redis = connect_redis('REDIS_URL', 'redis://localhost:6379/0', 'Redis')
  $redis2 = connect_redis('REDIS2_URL', 'redis://localhost:6380/0', 'Redis2')

  puts "Connected to Redis at #{ENV['REDIS_URL']} and Redis2 at #{ENV['REDIS2_URL']}"
end
