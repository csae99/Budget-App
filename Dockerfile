# Use Ruby 3.1.2 as the base image
FROM ruby:3.1.2

# Add a user 'deploy' with UID 1000 and GID 1000
RUN groupadd -r deploy -g 1000 && useradd -m -r -u 1000 -g deploy deploy

# Set the working directory in the container
WORKDIR /app

# Install system dependencies with --no-install-recommends
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        build-essential \
        nodejs \
        yarn \
        libpq-dev \
        imagemagick && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Bundler with a specific version
RUN gem install bundler:2.3.6

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle install

# Copy the rest of the application code into the container
COPY . .

# Precompile assets for production
RUN bundle exec rake assets:precompile

# Copy entrypoint script into the image
COPY entrypoint.sh /usr/bin/

# Ensure the entrypoint script is executable
RUN chmod +x /usr/bin/entrypoint.sh

# Expose the port on which the application will run
EXPOSE 3000

# Use the entrypoint script to handle server start and migrations
ENTRYPOINT ["entrypoint.sh"]

# Start the Rails application with Puma
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
