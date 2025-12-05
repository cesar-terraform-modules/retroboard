FROM node:20-alpine AS builder

WORKDIR /app

# Build argument for API URL
ARG NEXT_PUBLIC_API_HOST_URL=http://localhost:8000

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy application code
COPY . .

# Set environment variable for build
ENV NEXT_PUBLIC_API_HOST_URL=$NEXT_PUBLIC_API_HOST_URL

# Build the application (creates static export in 'out' directory)
RUN npm run build

# Production stage - use nginx for static files
FROM nginx:alpine

# Copy static files from builder
COPY --from=builder /app/out /usr/share/nginx/html

# Copy nginx configuration
RUN echo 'server { \
    listen 3000; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 3000

# Run nginx
CMD ["nginx", "-g", "daemon off;"]

