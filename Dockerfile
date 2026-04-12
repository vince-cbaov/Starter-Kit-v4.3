FROM nginx:stable-alpine

# Build-time argument selects the version
ARG APP_VERSION=v1

# Remove default NGINX content
RUN rm -rf /usr/share/nginx/html/*

# Copy ONLY the selected version directory
COPY app/${APP_VERSION}/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]