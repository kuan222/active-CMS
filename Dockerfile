RUN apk add --no-cache python3 make g++ 



# Add build dependencies for node-gyp
RUN apk add --no-cache python3 make g++ 

COPY package*.json ./
RUN npm install

# Use a Node version that matches your project
FROM node:20-slim AS builder
WORKDIR /app

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


