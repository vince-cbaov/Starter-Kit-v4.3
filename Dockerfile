FROM nginx:stable-alpine

# Build-time argument to control version behaviour
ARG APP_VERSION=v2

# Remove default NGINX index
RUN rm -rf /usr/share/nginx/html/*

# Copy full app folder into container
COPY app/ /usr/share/nginx/html/

# Switch which HTML file is served based on version
# v1  → index.html
# v2  → index_with_logo.html becomes index.html
RUN if [ "$APP_VERSION" = "v2" ]; then \
      echo "Using v2 index_with_logo.html"; \
      mv /usr/share/nginx/html/index_with_logo.html /usr/share/nginx/html/index.html; \
    else \
      echo "Using v1 index.html"; \
    fi

# Expose port 80 for AKS LoadBalancer service
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
