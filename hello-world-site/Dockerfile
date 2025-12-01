FROM nginx:latest

COPY ./nginx.conf /etc/nginx/conf.d/default.conf

COPY ./index.html /app/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]