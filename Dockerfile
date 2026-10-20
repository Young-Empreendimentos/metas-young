# Painel Metas Young — servidor estático Node, sem dependências.
FROM node:20-alpine
WORKDIR /app
COPY server.js ./
COPY web ./web
ENV PORT=3000
EXPOSE 3000
CMD ["node", "server.js"]
