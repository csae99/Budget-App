#!/bin/bash

# Function to check if the new environment is ready
check_environment() {
  local service_url=$1
  local retries=5
  local count=0

  until curl -s --head --request GET $service_url | grep "200 OK" > /dev/null; do
    count=$((count+1))
    if [ $count -ge $retries ]; then
      echo "Environment $service_url is not ready after $retries attempts."
      return 1
    fi
    echo "Waiting for $service_url to be ready..."
    sleep 5
  done

  return 0
}

# Determine current deployment and set the new deployment
CURRENT_DEPLOYMENT=$(docker-compose exec -T nginx grep "server " /etc/nginx/nginx.conf | grep -v "backup" | awk '{print $2}')

if [ "$CURRENT_DEPLOYMENT" == "web-blue:3000;" ]; then
  NEW_DEPLOYMENT="web-green:3000"
  NEW_DEPLOYMENT_URL="http://localhost:3002"
else
  NEW_DEPLOYMENT="web-blue:3000"
  NEW_DEPLOYMENT_URL="http://localhost:3001"
fi

# Check if the new environment is ready
if check_environment $NEW_DEPLOYMENT_URL; then
  echo "Switching traffic to $NEW_DEPLOYMENT"

  # Update NGINX configuration
  cat > nginx.conf <<EOL
events {}

http {
    upstream backend {
        server $NEW_DEPLOYMENT;
        server ${CURRENT_DEPLOYMENT%?} backup;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOL

  # Copy the updated configuration to the NGINX container and reload NGINX
  docker cp nginx.conf budget-app_nginx_1:/etc/nginx/nginx.conf
  docker-compose exec -T nginx nginx -s reload
  echo "Traffic switched to $NEW_DEPLOYMENT"
else
  echo "Failed to switch traffic. New environment is not ready."
fi
