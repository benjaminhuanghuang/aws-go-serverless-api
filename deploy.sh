env GOOS=linux GOARCH=amd64 go build -o ./temp/main ./books


zip -j ./temp/main.zip ./temp/main


aws lambda update-function-code --function-name books \
--zip-file fileb://./temp/main.zip