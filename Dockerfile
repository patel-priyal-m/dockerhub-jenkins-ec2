# Use nginx alpine - super lightweight (only ~5MB!)
FROM nginx:alpine

# Copy static files to nginx html directory
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# nginx starts automatically with alpine image
