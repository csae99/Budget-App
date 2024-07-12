Sure, let's break down the configuration step by step:

### Dockerfile

The Dockerfile is used to create a Docker image for your Ruby on Rails application. Here's what each part does:

```Dockerfile
FROM ruby:3.1.2
```
- This specifies the base image for the Docker build. In this case, it’s the official Ruby 3.1.2 image.

```Dockerfile
WORKDIR /app
```
- This sets the working directory inside the container to `/app`.

```Dockerfile
RUN apt-get update -qq && apt-get install -y nodejs yarn
```
- This updates the package lists and installs Node.js and Yarn. Node.js is required to compile JavaScript assets, and Yarn is a package manager for JavaScript.

```Dockerfile
COPY Gemfile Gemfile.lock ./
```
- This copies the `Gemfile` and `Gemfile.lock` into the working directory inside the container.

```Dockerfile
RUN gem install bundler:2.3.6
RUN bundle install
```
- This installs a specific version of Bundler and then runs `bundle install` to install Ruby dependencies specified in the Gemfile.

```Dockerfile
COPY . .
```
- This copies the rest of the application code into the working directory inside the container.

```Dockerfile
RUN bundle exec rake assets:precompile
```
- This precompiles the assets, which is a necessary step for production environments to optimize the delivery of static assets.

```Dockerfile
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
```
- This copies the entrypoint script into the `/usr/bin` directory inside the container and makes it executable.

```Dockerfile
EXPOSE 3000
```
- This informs Docker that the container listens on port 3000.

```Dockerfile
ENTRYPOINT ["entrypoint.sh"]
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]
```
- `ENTRYPOINT` specifies the script to run to start the container. `CMD` provides default arguments for the entrypoint script. In this case, it removes any pre-existing server PID file and starts the Rails server.

### entrypoint.sh

This script ensures that necessary setup tasks are performed before the main process (Rails server) starts.

```bash
#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Run database migrations
bundle exec rake db:migrate

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
```
- `#!/bin/bash` specifies the script should be run in the bash shell.
- `set -e` makes the script exit immediately if any command fails.
- `rm -f /app/tmp/pids/server.pid` removes any existing server PID file to prevent conflicts.
- `bundle exec rake db:migrate` runs database migrations to ensure the database schema is up to date.
- `exec "$@"` runs the main process (Rails server in this case) as specified in the Dockerfile’s `CMD`.

### docker-compose.yml

This file defines the multi-container setup for your application using Docker Compose.

```yaml
version: '3.9'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
    depends_on:
      - db
    env_file:
      - .env  # Ensure this file exists with necessary environment variables
    environment:
      - POSTGRES_USER=Budgy
      - POSTGRES_PASSWORD=Budgy
      - POSTGRES_DB=budgy_development
    command: ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]
  db:
    image: postgres:14.1
    volumes:
      - ./pgdata:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=Budgy
      - POSTGRES_PASSWORD=Budgy
      - POSTGRES_DB=budgy_development

volumes:
  pgdata:
```
- `version: '3.9'` specifies the version of Docker Compose syntax.
- `services:` defines the services that make up your application.

**Service: `web`**
- `build: .` builds the Docker image for the web service using the Dockerfile in the current directory.
- `ports: - "3000:3000"` maps port 3000 on the host to port 3000 in the container.
- `volumes: - .:/app` mounts the current directory on the host to `/app` in the container, allowing for live code changes.
- `depends_on: - db` specifies that the `web` service depends on the `db` service, ensuring it starts after the database.
- `env_file: - .env` loads environment variables from the `.env` file.
- `environment:` defines additional environment variables directly.
- `command:` specifies the command to run in the container, in this case starting the Rails server after ensuring no stale server PID file exists.

**Service: `db`**
- `image: postgres:14.1` specifies the Docker image for the database service.
- `volumes: - ./pgdata:/var/lib/postgresql/data` mounts a directory on the host to persist PostgreSQL data.
- `environment:` sets environment variables for the PostgreSQL container.

**volumes:**
- `pgdata:` defines a named volume for persisting PostgreSQL data.

### .env

This file contains environment variables used by the Docker Compose configuration.

```env
# PostgreSQL settings
POSTGRES_USER=Budgy
POSTGRES_PASSWORD=Budgy
POSTGRES_DB=budgy_development

# Rails environment settings
RAILS_ENV=development
DATABASE_URL=postgres://Budgy:Budgy@db:5432/budgy_development
```
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` are used to configure the PostgreSQL database.
- `RAILS_ENV=development` sets the Rails environment to development.
- `DATABASE_URL` provides the database connection string for the Rails application.

This configuration ensures that when you run `docker-compose up`, it will:
1. Build the Docker image for your Rails application.
2. Start a PostgreSQL database container.
3. Run the database migrations.
4. Start the Rails server, making the application accessible on port 3000.


============================================================================================================================
### Notes on Zero-Downtime Deployment Process

#### Overview
- **Objective:** Achieve zero-downtime deployments using NGINX and Docker Compose with Blue-Green deployment strategy.
- **Components:** Two Rails applications (`web-blue` and `web-green`), PostgreSQL, Redis, and NGINX for load balancing.

#### Steps

1. **Set Up Docker Compose Services:**
    - Define services for `web-blue`, `web-green`, `db`, `redis`, `redis2`, and `nginx` in `docker-compose.yml`.
    - Use shared volumes for PostgreSQL and Redis data.

2. **Configure NGINX:**
    - Use `Dockerfile.nginx` to build a custom NGINX image.
    - `nginx.conf` should define an upstream block with `web-blue` and `web-green`, marking one as a backup.

3. **Deployment Workflow:**
    1. **Build and Start Services:**
        ```sh
        docker-compose build
        docker-compose up -d
        ```
        ```
    2. **Verify and Stop Old Environment:**
        ```sh
        docker-compose stop web-blue  # or web-green
        ```

#### Key Files

- **`Dockerfile.nginx`:** Builds the custom NGINX image.
- **`nginx.conf`:** NGINX configuration file.
- **`docker-compose.yml`:** Defines all services.

#### Diagram

Below is a simplified diagram to illustrate the process:

```
                   +-------------------+
                   |   Load Balancer   |
                   |       (NGINX)     |
                   +-------------------+
                            |
            +---------------+---------------+
            |                               |
+-----------------------+       +-----------------------+
|     web-blue:3000     |       |     web-green:3000    |
|   Rails Application   |       |   Rails Application   |
+-----------------------+       +-----------------------+
            |                               |
            +---------------+---------------+
                            |
                   +-------------------+
                   |     Database      |
                   |    (PostgreSQL)   |
                   +-------------------+
                            |
                   +-------------------+
                   |      Cache        |
                   |      (Redis)      |
                   +-------------------+
```

### Detailed Explanation

1. **NGINX Load Balancer:** 
   - Acts as the entry point for all incoming traffic.
   - Routes traffic to either `web-blue` or `web-green` based on the current configuration.

2. **Blue-Green Deployment Strategy:**
   - Deploy new changes to the inactive environment (e.g., `web-green`).
   - Ensure the new environment is ready and healthy.
   - Update NGINX to switch traffic to the new environment.
   - Stop the old environment to complete the deployment.

3. **Zero-Downtime:**
   - By using NGINX and the Blue-Green strategy, traffic can be seamlessly switched between environments without downtime.

This process ensures that users experience no downtime during deployments, with a smooth transition between the blue and green environments.

```yaml
version: '3.9'

services:
  web-blue:
    build: .
    ports:
      - "127.0.0.1:3001:3000"
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
      - redis2
    env_file:
      - .env
    environment:
      - POSTGRES_USER=Budgy
      - POSTGRES_PASSWORD=Budgy
      - POSTGRES_DB=budgy_development
    command: ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]

  web-green:
    build: .
    ports:
      - "127.0.0.1:3002:3000"
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
      - redis2
    env_file:
      - .env
    environment:
      - POSTGRES_USER=Budgy
      - POSTGRES_PASSWORD=Budgy
      - POSTGRES_DB=budgy_development
    command: ["bash", "-c", "rm-f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"]

  db:
    image: postgres:15.3
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=Budgy
      - POSTGRES_PASSWORD=Budgy
      - POSTGRES_DB=budgy_development
    ports:
      - "127.0.0.1:5432:5432"

  redis:
    image: redis:7.2.5
    ports:
      - "127.0.0.1:6381:6379"
    volumes:
      - redis-data:/data

  redis2:
    image: redis:2.8
    container_name: redis2
    ports:
      - "127.0.0.1:6382:6379"
    volumes:
      - redis-data2:/data

  nginx:
    build:
      context: .
      dockerfile: Dockerfile.nginx
    ports:
      - "80:80"
    depends_on:
      - web-blue
      - web-green

volumes:
  pgdata:
  redis-data:
  redis-data2:
```


Let's address each of these questions one by one in the context of your Docker-based Ruby on Rails application with React front-end.

### 1. What about cron jobs?

**Running Cron Jobs in Docker:**
Cron jobs can be handled in a Docker environment using a separate container specifically for cron tasks. You can create a Docker container with a crontab that runs your desired tasks.

Here’s an example of how you might set up a cron container:

**Dockerfile.cron**
```Dockerfile
FROM ruby:3.1.2

WORKDIR /app

# Install dependencies
RUN apt-get update -qq && apt-get install -y cron

# Copy application code
COPY . .

# Install gems
RUN bundle install

# Copy the crontab file to the cron.d directory
COPY cronjobs /etc/cron.d/my-cron-jobs

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/my-cron-jobs

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log
```

**cronjobs file**
```
# Example of a cron job running a Rails task every hour
0 * * * * cd /app && RAILS_ENV=production bundle exec rake my:task >> /var/log/cron.log 2>&1
```

**docker-compose.yml**
```yaml
cron:
  build:
    context: .
    dockerfile: Dockerfile.cron
  volumes:
    - .:/app
  environment:
    - RAILS_ENV=production
  networks:
    - budget-net
```

### 2. What about React code?

**Serving React Code in a Rails Application:**
Your React code can be managed and served by the Rails application using the Webpacker gem. Here’s how you might set it up:

1. **Ensure Webpacker is Installed:**
   Make sure Webpacker is included in your Gemfile:
   ```ruby
   gem 'webpacker'
   ```

2. **Webpacker Configuration:**
   Use Webpacker to manage your JavaScript assets. Typically, you will have a `webpacker.yml` configuration file in the `config` directory.

3. **Include React:**
   Run the following command to set up React in your Rails app:
   ```bash
   rails webpacker:install:react
   ```

### 3. How will the db be backed up?

**Database Backup Strategy:**
You can back up your PostgreSQL database using tools like `pg_dump`. Here’s an example of how to create a backup container:

**docker-compose.yml**
```yaml
db-backup:
  image: postgres:15.3
  volumes:
    - pgdata:/var/lib/postgresql/data
    - ./db_backups:/backups
  entrypoint: ["bash", "-c", "pg_dump -U $POSTGRES_USER -d $POSTGRES_DB > /backups/db_backup.sql"]
  environment:
    - POSTGRES_USER=${POSTGRES_USER}
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    - POSTGRES_DB=${POSTGRES_DB}
  networks:
    - budget-net
```

**Running the Backup:**
To create a backup, you can run:
```bash
docker-compose run db-backup
```

### 4. How is the database persisted? Do we need volume or commit? / EC2 backup any issue

**Database Persistence:**
Database persistence in Docker is typically managed using Docker volumes. In your `docker-compose.yml`, you have already set up a volume for your PostgreSQL database:

```yaml
volumes:
  pgdata:
```

This ensures that your database data is persisted across container restarts and deployments.

**Backup Considerations on EC2:**
When deploying on EC2, ensure that your volume for the database is correctly backed up. You can use Amazon EBS snapshots for this purpose. Regularly create snapshots of your EBS volumes to ensure data safety.

### 5. How will local uploaded files be persisted across deployments?

**Persisting Uploaded Files:**
Local uploaded files should be stored in a persistent volume to ensure they are not lost across deployments. You can define a volume in your `docker-compose.yml` for this purpose:

```yaml
volumes:
  uploads:
```

Then, mount this volume in your web service:

```yaml
web-blue:
  build: .
  container_name: web-blue
  ports:
    - "127.0.0.1:3001:3000"
  volumes:
    - .:/app
    - uploads:/app/public/uploads
  ...
```

This ensures that files uploaded to `/app/public/uploads` are persisted.

### Comprehensive `docker-compose.yml` Example:
Here’s an updated `docker-compose.yml` incorporating the above points:

```yaml
version: '3.9'

services:
  web-blue:
    build: .
    container_name: web-blue
    ports:
      - "127.0.0.1:3001:3000"
    volumes:
      - .:/app
      - uploads:/app/public/uploads
    depends_on:
      - db
      - redis
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - REDIS_URL=${REDIS_URL}
    command: ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
    networks:
      - budget-net

  web-green:
    build: .
    container_name: web-green
    ports:
      - "127.0.0.1:3002:3000"
    volumes:
      - .:/app
      - uploads:/app/public/uploads
    depends_on:
      - db
      - redis
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - REDIS_URL=${REDIS_URL}
    command: ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"]
    networks:
      - budget-net

  db:
    image: postgres:15.3
    container_name: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    networks:
      - budget-net

  redis:
    image: redis:7.2.5
    container_name: redis
    ports:
      - "127.0.0.1:6379:6379"  
    volumes:
      - redis-data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
    networks:
      - budget-net

  sidekiq:
    build: .
    container_name: sidekiq
    command: ["bundle", "exec", "sidekiq", "-C", "config/sidekiq.yml"]
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - REDIS_URL=${REDIS_URL}
    networks:
      - budget-net

  nginx:
    build:
      context: .
      dockerfile: Dockerfile.nginx
    container_name: nginx
    ports:
      - "80:80"
    depends_on:
      - web-blue
      - web-green
    networks:
      - budget-net

  cron:
    build:
      context: .
      dockerfile: Dockerfile.cron
    volumes:
      - .:/app
    environment:
      - RAILS_ENV=production
    networks:
      - budget-net

volumes:
  pgdata:
  redis-data:
  uploads:

networks:
  budget-net:
    driver: bridge
```

This configuration ensures that your application handles cron jobs, serves React code, backs up and persists the database, and maintains local uploaded files across deployments.