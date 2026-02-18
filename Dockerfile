# 1. Start the first stage and NAME IT 'builder'
FROM node:18-alpine AS builder

# 2. Install the build tools we discussed earlier
RUN apk add --no-cache python3 make g++

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# If you have a build step (like npm run prod for Laravel Mix), add it here:
# RUN npm run prod

# 3. Start the second (final) stage
FROM node:20-slim
WORKDIR /app

# 4. Now this 'from=builder' will work correctly!
COPY --from=builder /app .

EXPOSE 3000
CMD ["npm", "start"]

