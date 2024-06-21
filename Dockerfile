# Stage 1: Build the Go application
FROM golang:1.22-alpine as builder

ARG REVISION

WORKDIR /podinfo

# Copy the Go modules manifests and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the podinfo and podcli binaries
RUN CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" -a -o bin/podinfo cmd/podinfo/*
RUN CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/stefanprodan/podinfo/pkg/version.REVISION=${REVISION}" -a -o bin/podcli cmd/podcli/*

# Stage 2: Create the final image
FROM alpine:3.20

ARG BUILD_DATE
ARG VERSION
ARG REVISION

# Create app user and install necessary packages
RUN addgroup -S app && adduser -S -G app app && apk --no-cache add ca-certificates curl netcat-openbsd

WORKDIR /home/app

# Copy the binaries from the builder stage
COPY --from=builder /podinfo/bin/podinfo .
COPY --from=builder /podinfo/bin/podcli /usr/local/bin/podcli
COPY ./ui ./ui

# Change ownership of the copied files
RUN chown -R app:app ./

USER app

# Set the entrypoint command
CMD ["./podinfo"]
