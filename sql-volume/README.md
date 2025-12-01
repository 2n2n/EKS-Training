1. Build the image `docker build -t sql-test-img .`
2. Run the image `docker run --name sql-test-container -d -e MYSQL_ALLOW_EMPTY_PASSWORD=true sql-test-img`
3. access the container via `docker exec -it sql-test-container mysql`
