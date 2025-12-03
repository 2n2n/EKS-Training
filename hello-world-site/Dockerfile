FROM nginx:latest

COPY ./nginx.conf /etc/nginx/conf.d/default.conf

WORKDIR /app/html 

COPY ./index.html ./index.html

RUN apt-get update && apt-get install -y curl
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g npm@latest
RUN npm install -g express
RUN npm install -g express-generator
RUN npm install -g express-generator

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]