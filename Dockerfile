# build image
FROM rust:latest@sha256:ad7e5fd44a71f317c88993a64d4073f9050516cd420ddacd90b7d43829f29f26 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:5724d31208341cef9af6ae2be86be9cda6a87271f362a03481a522c9c19d401b
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
