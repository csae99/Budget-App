# config/initializers/sidekiq.rb

require 'yaml'

Sidekiq.configure_server do |config|
  begin
    sidekiq_config = YAML.load_file(Rails.root.join('config', 'sidekiq.yml'))
  rescue Errno::ENOENT, Psych::SyntaxError => e
    Rails.logger.error "Failed to load Sidekiq configuration: #{e.message}"
    sidekiq_config = {}  # Provide a default configuration or handle as needed
  end

  config.redis = {
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    network_timeout: 5
  }

  if Rails.env.production?
    config.merge!(sidekiq_config['production'] || {})
  elsif Rails.env.staging?
    config.merge!(sidekiq_config['staging'] || {})
  else
    config.merge!(sidekiq_config['development'] || {})
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    network_timeout: 5
  }
end

Sidekiq.logger = Rails.logger
