FROM golang:1

RUN apt-get update && \
    apt-get install -y zip

ADD main.go .
RUN go get -d

RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o main main.go

ADD app .
ADD bin/php bin

RUN zip app.zip php bin config src vendor bin/handler .env main -rq
