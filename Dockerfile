# build image
FROM rust:latest@sha256:ad7e5fd44a71f317c88993a64d4073f9050516cd420ddacd90b7d43829f29f26 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:5484adc33b4c352c5a9f4c4ae295fc49aed1cb54a7a0712a1b29674fb6f4f10f
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
