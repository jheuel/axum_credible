# build image
FROM rust:latest@sha256:251cec8da4689d180f124ef00024c2f83f79d9bf984e43c180a598119e326b84 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:50db38a20a279ccf50761943c36f9e82378f92ef512293e1239b26bb77a8b496
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
