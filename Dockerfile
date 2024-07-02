FROM ruby:3.1.2

# Set the working directory in the container
WORKDIR /app

# Install necessary dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    nodejs \
    yarn \
    libpq-dev \
    imagemagick \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install Bundler and dependencies
RUN gem install bundler:2.3.6
RUN bundle install

# Copy the rest of the application code into the container
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile

# Copy entrypoint script
COPY entrypoint.sh /usr/bin/

# Ensure the entrypoint script is executable
RUN chmod +x /usr/bin/entrypoint.sh

# Expose the port on which the application will run
EXPOSE 3000

# Use the entrypoint script to handle server start and migrations
ENTRYPOINT ["entrypoint.sh"]

# Start the Rails application
# CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
