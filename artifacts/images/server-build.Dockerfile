# Build the proxy-server binary

ARG BUILDARCH
ARG GO_TOOLCHAIN
ARG GO_VERSION
ARG BASEIMAGE

FROM golang:1.22.5 AS builder

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
COPY proto/  proto/

# Build
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -mod=vendor -v -a -ldflags '-extldflags "-static"' -o proxy-server sigs.k8s.io/apiserver-network-proxy/cmd/server

FROM gcr.io/distroless/static-debian11:nonroot

WORKDIR /
COPY --from=builder /go/src/sigs.k8s.io/apiserver-network-proxy/proxy-server .
ENTRYPOINT ["/proxy-server"]
