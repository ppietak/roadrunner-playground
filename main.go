package main

import (
    "context"
    "github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/events"
    "github.com/spiral/roadrunner"
    "os"
    "time"
    "fmt"
    "strings"
    "errors"
)

var srv *roadrunner.Server

func init() {
    os.Setenv("PATH", os.Getenv("PATH")+":"+os.Getenv("LAMBDA_TASK_ROOT"))
    os.Setenv("LD_LIBRARY_PATH", "./lib:/lib64:/usr/lib64")

    srv = roadrunner.NewServer(
        &roadrunner.ServerConfig{
            Command: "bin/handler app:lambda",
            Relay:   "pipes",
            Pool: &roadrunner.Config{
                NumWorkers:      1,
                MaxJobs:         100,
                AllocateTimeout: time.Second,
                DestroyTimeout:  time.Second,
            },
        },
    )
}

func main() {
    if err := srv.Start(); err != nil {
        panic(err)
    }
    defer srv.Stop()

    lambda.Start(handle)
}

func handle(ctx context.Context, sqsEvent events.SQSEvent) (string, error) {
    for _, message := range sqsEvent.Records {
		res, err := srv.Exec(&roadrunner.Payload{Body: []byte(message.Body)})
		if res != nil {
	        fmt.Printf("%s\n", res.String())
	        break
        }

		if err != nil {
            result := strings.SplitN(err.Error(), "\n", 2)
	        fmt.Printf("%s\n", result[1])
            return result[0], errors.New(result[0])
		}
	}

    return "OK", nil
}
