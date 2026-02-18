# 1. First, define the base image (crucial!)
FROM node:18-alpine

# 2. Then, add the build dependencies
RUN apk add --no-cache python3 make g++

# 3. Rest of your build steps
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .


# REQUIRED: Install tools to fix the "gyp Build failed" error
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install
COPY . .

# Final stage
FROM node:20-slim
WORKDIR /app
COPY --from=builder /app .
EXPOSE 3000
CMD ["npm", "start"]


