# build image
FROM rust:latest@sha256:8e5fb4afd20ad09c60b4b2466aa243a9f991d1dc2482621a8f101c9656c646ae AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:5484adc33b4c352c5a9f4c4ae295fc49aed1cb54a7a0712a1b29674fb6f4f10f
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
