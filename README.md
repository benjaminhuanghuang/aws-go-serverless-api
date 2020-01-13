# aws-go-serverless-api
-[How to build a Serverless API with Go and AWS Lambda](https://www.alexedwards.net/blog/serverless-api-with-go-and-aws-lambda)


## Setting up the AWS CLI
1. Install AWS CLI

2. Config CLI
```
  asw config
```

## Create role which defines the permission that the lambda function will have when it is running.
```
aws iam create-role --role-name ben-lambda-executor --assume-role-policy-document file:///lambda-policy.json

aws iam attach-role-policy --role-name ben-lambda-executor \
--policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

## Creating and deploying an Lambda function
1. Install package
```
  go get github.com/aws/aws-lambda-go/lambda
```

2. Build and zip the executable
```
  env GOOS=linux GOARCH=amd64 go build -o ./temp/main ./books

  # the executable must be in the root of the zip file
  zip -j ./main.zip ./main
```

3. Deploy 
Create lambda function at first time
```
aws lambda create-function --function-name books --runtime go1.x \
--role arn:aws:iam::<account-id>:role/ben-lambda-executor \
--handler main --zip-file fileb://main.zip
```
update
```
aws lambda update-function-code --function-name books \
--zip-file fileb://./temp/main.zip
```

4. Test lambda
```
aws lambda invoke --function-name books output.json
```

## Using DynamoDB
1. Create tabel
```
aws dynamodb create-table --table-name ben-books \
--attribute-definitions AttributeName=ISBN,AttributeType=S \
--key-schema AttributeName=ISBN,KeyType=HASH \
--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```
2. Put data
```
aws dynamodb put-item --table-name ben-books --item '{"ISBN": {"S": "978-1420931693"}, "Title": {"S": "The Republic"}, "Author":  {"S": "Plato"}}'

aws dynamodb put-item --table-name ben-books --item '{"ISBN": {"S": "978-0486298238"}, "Title": {"S": "Meditations"},  "Author":  {"S": "Marcus Aurelius"}}'
```

3. Install package for DynamoDB
```
  go get github.com/aws/aws-sdk-go
```

4. Attach policy 'dynamodb-item-crud-policy' to role
```
aws iam put-role-policy --role-name ben-lambda-executor \
--policy-name dynamodb-item-crud-policy \
--policy-document file://./dynamodb-policy.json
```
Without this, lambda returns error "AccessDeniedException"


## Create API using AWS API Gateway
```
  aws apigateway create-rest-api --name ben-bookstore
```
the API id is 'jcy04tx033'

Use api id to get id of the root API resource ("/")
```
  aws apigateway get-resources --rest-api-id jcy04tx033
```
5zzv9hcv7a

Create resource /books
```
aws apigateway create-resource --rest-api-id jcy04tx033 \
--parent-id 5zzv9hcv7a --path-part books
```
bq93a2

Create put method
```
aws apigateway put-method --rest-api-id jcy04tx033 \
--resource-id bq93a2 --http-method ANY \
--authorization-type NONE
```

integrate the resource with our lambda function
```
aws apigateway put-integration --rest-api-id jcy04tx033 \
--resource-id bq93a2 --http-method ANY --type AWS_PROXY \
--integration-http-method POST \
--uri arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:173116748583:function:books/invocations
```

Give API gateway permission to execute lambda function
```
aws lambda add-permission --function-name books --statement-id 448baba2-5b7f-4f05-8b07-a2c983f59768 \
--action lambda:InvokeFunction --principal apigateway.amazonaws.com \
--source-arn arn:aws:execute-api:us-west-2:173116748583:jcy04tx033/*/*/*
```
--statement-id parameter is a GUID, we can create it at https://www.guidgenerator.com/

Test API
```
aws apigateway test-invoke-method --rest-api-id jcy04tx033 \
--resource-id bq93a2 \
--http-method "GET" \
--path-with-query-string "/books?isbn=978-1420931693"
```


## Query the log
Anything sent to os.Stderr will be logged to the AWS Cloudwatch service. So we can query Cloudwatch for errors like so:
```
aws logs filter-log-events --log-group-name /aws/lambda/books \
--filter-pattern "ERROR"
```

## Deploy the API
```
aws apigateway create-deployment --rest-api-id jcy04tx033 \
--stage-name staging
```
get id: ifbr2a

The API should be accessible at 
```
https://<rest-api-id>.execute-api.us-west-2.amazonaws.com/staging
```