# Use Nginx as base
FROM nginx:alpine

# Copy static files
COPY public /usr/share/nginx/html

# Copy custom Nginx config (optional, but keeps your config)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Run Nginx
CMD ["nginx", "-g", "daemon off;"]