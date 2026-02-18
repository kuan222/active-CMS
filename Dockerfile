# Use an older Node version compatible with Laravel Mix 2.0
FROM node:10-alpine AS builder

# Install build tools required for node-gyp
RUN apk add --no-cache python2 make g++ gcc

WORKDIR /app
COPY package*.json ./

# Force install if you hit dependency resolution issues
RUN npm install

COPY . .
# Run your build step (Laravel Mix 2.0 uses 'dev' or 'production' usually)
RUN npm run dev

# Final Stage
FROM node:10-alpine
WORKDIR /app
COPY --from=builder /app .
EXPOSE 3000
CMD ["npm", "start"]
