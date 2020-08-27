FROM golang:1.13.8 as builder

# Set necessary environmet variables needed for our image
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

RUN apt update \
    && apt-get install -y --no-install-recommends \
          autoconf \
          automake \
          libtool \
          curl \
          make \
          g++ \
          unzip \
          protobuf-c-compiler

ENV PROTOC_ZIP=protoc-3.7.1-linux-x86_64.zip

RUN curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/$PROTOC_ZIP && \
  unzip -o $PROTOC_ZIP -d /usr/local bin/protoc && \
  unzip -o $PROTOC_ZIP -d /usr/local 'include/*' && \
  rm -f $PROTOC_ZIP

RUN go get -u github.com/golang/protobuf/protoc-gen-go

# Install the right "yarn"
# This is only needed for the web build
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && apt-get install yarn -y

# Move to working directory /build
WORKDIR /build

# Copy and download dependency using go mod
COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .

RUN make build

# Copy all the built stuff into a smaller image
FROM alpine

ARG svc_name

COPY --from=builder /build/$svc_name/target /usr/local/bin/

# ARG variables arent available for ENTRYPOINT
ENV SVC_NAME $svc_name
ENTRYPOINT cd /usr/local/bin && $SVC_NAME
