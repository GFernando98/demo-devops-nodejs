# Install production dependencies.
FROM node:18-alpine as deps

WORKDIR /app

COPY package*.json ./

RUN npm ci && npm cache clean --force

# Production runtime.
FROM node:18-alpine as runtime

# Create a non-root user to run the application.
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodeuser -u 1001 -G nodejs

WORKDIR /app

# Copy the production dependencies and application code.
COPY --from=deps --chown=nodeuser:nodejs /app/node_modules ./node_modules

# Copy the rest of the application code, ensuring correct ownership for the non-root user.
COPY --chown=nodeuser:nodejs . .

# Create a directory for application data with appropriate permissions.
RUN mkdir -p /app/data && chown -R nodeuser:nodejs /app/data

# Run the application as the non-root user.
USER nodeuser

# Environment variables for production.
# Database credentials and other sensitive information should ideally be passed in at runtime, but for the sake of this example, we're setting them here. In a real-world scenario, consider using Docker secrets or environment variables passed at runtime for better security.
ENV NODE_ENV=production \
    PORT=8000 \
    DATABASE_NAME="/app/data/dev.sqlite" \
    DATABASE_USER="user" \
    DATABASE_PASSWORD="password"

EXPOSE 8000

# Health check to ensure the application is running and responsive.
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8000/ || exit 1

CMD ["node", "index.js"]
