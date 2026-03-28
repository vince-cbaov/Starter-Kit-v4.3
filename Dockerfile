FROM nginx:stable-alpine

# Remove default NGINX index
RUN rm -rf /usr/share/nginx/html/*

# Copy full app folder into container
COPY app/ /usr/share/nginx/html/

# Ensure the main page is index.html (Option A)
# Your CI/CD process replaces index.html with v1 or v2 before build.

# Expose port 80 for AKS LoadBalancer service
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]