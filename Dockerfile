FROM node:latest

WORKDIR /infra_week_3

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
