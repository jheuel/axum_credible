# build image
FROM rust:latest@sha256:af030eadc07fd0e0e36b54b56eda8d6217b57c67f58d39a31838220be4a2d5e6 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:1c25564b03942d874bf6a2b71f2062b71af8bc1475aa873c523e6f7c8fa29e60
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
