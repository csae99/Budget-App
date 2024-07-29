# config/initializers/redis.rb

require 'redis'

# Redis for primary usage
$redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/0"))

# Redis2 for secondary usage
$redis2 = Redis.new(url: ENV.fetch("REDIS2_URL", "redis://redis2:6380/0"))
