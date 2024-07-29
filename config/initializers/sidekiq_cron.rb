# config/initializers/sidekiq_cron.rb

Sidekiq.configure_server do |config|
    schedule_file = Rails.root.join('config', 'sidekiq_schedule.yml')
  
    if File.exists?(schedule_file)
      Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
    end
  end
  
