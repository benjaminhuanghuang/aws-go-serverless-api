env GOOS=linux GOARCH=amd64 go build -o ./temp/main ./books


zip -j ./temp/main.zip ./temp/main


