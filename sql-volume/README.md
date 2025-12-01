1. Build the image `docker build docker build -t sql-test .`
2. Run the image `docker run --name sql-test -d -e MYSQL_ALLOW_EMPTY_PASSWORD=true mysql_test`
3. access the container via `docker exec -it sql-test mysql`
