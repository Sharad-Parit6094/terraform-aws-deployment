# microservice/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production || true
COPY . .
EXPOSE 8080
CMD ["node", "app.js"]
