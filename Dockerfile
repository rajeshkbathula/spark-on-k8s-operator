ARG SPARK_IMAGE=rajeshkbathula/spark:3.1.1-hdp3.2

FROM golang:1.15.2-alpine as builder

WORKDIR /workspace

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# Cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source code
COPY main.go main.go
COPY pkg/ pkg/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -a -o /usr/bin/spark-operator main.go

FROM ${SPARK_IMAGE}
USER root
COPY --from=builder /usr/bin/spark-operator /usr/bin/
RUN apt-get update \
    && apt-get install -y openssl curl tini \
    && rm -rf /var/lib/apt/lists/*
COPY hack/gencerts.sh /usr/bin/

COPY entrypoint.sh /usr/bin/
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

