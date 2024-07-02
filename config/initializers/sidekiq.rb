Sidekiq.configure_server do |config|
  sidekiq_config = YAML.load_file(Rails.root.join('config', 'sidekiq.yml'))

  config.redis = { url: 'redis://localhost:6379/0', network_timeout: 5 }

  if Rails.env.production?
    config[:options] ||= {}
    config[:options].merge!(sidekiq_config['production'] || {})
  elsif Rails.env.staging?
    config[:options] ||= {}
    config[:options].merge!(sidekiq_config['staging'] || {})
  else
    config[:options] ||= {}
    config[:options].merge!(sidekiq_config['development'] || {})
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/0', network_timeout: 5 }
end
