# Build the http test server binary

ARG BUILDARCH
ARG GO_TOOLCHAIN
ARG GO_VERSION
ARG BASEIMAGE

FROM golang:1.23.2 AS builder

ENV HTTP_PROXY=http://192.168.1.5:7890/
ENV HTTPS_PROXY=http://192.168.1.5:7890/
ENV NO_PROXY=localhost,127.0.0.1,jjpt.harbor.com,dockerhub.kubekey.local

# Copy in the go src
WORKDIR /go/src/sigs.k8s.io/apiserver-network-proxy

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# We have a replace directive for konnectivity-client in go.mod
COPY konnectivity-client/ konnectivity-client/

# Copy vendored modules
COPY vendor/ vendor/

# Copy the sources
COPY pkg/    pkg/
COPY cmd/    cmd/

# Build
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -mod=vendor -v -a -ldflags '-extldflags "-static"' -o http-test-server sigs.k8s.io/apiserver-network-proxy/cmd/test-server

FROM ${BASEIMAGE}

WORKDIR /
COPY --from=builder /go/src/sigs.k8s.io/apiserver-network-proxy/http-test-server .
ENTRYPOINT ["/http-test-server"]
