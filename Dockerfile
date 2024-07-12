# Use a Ruby base image
FROM ruby:3.1.2

# Create a deploy group and user
RUN groupadd -r deploy -g 1000 && useradd -m -r -u 1000 -g deploy deploy

# Set up the working directory
WORKDIR /app

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    gnupg \
    nodejs \
    libpq-dev \
    imagemagick && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Yarn GPG key and Yarn repository
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

# Install bundler
RUN gem install bundler:2.3.6

# Copy Gemfile and Gemfile.lock first to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the rest of the application code
COPY . ./

# Install JavaScript dependencies
RUN yarn install

# Precompile assets
RUN bundle exec rake assets:precompile

# Expose the application port
EXPOSE 3000

# Start the Rails server
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
