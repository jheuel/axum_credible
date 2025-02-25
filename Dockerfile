# build image
FROM rust:latest@sha256:9285bed250441d504928a5bc1ad4694a9acc5d1873e72cb9d12b8e1dc2de6ee5 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:5484adc33b4c352c5a9f4c4ae295fc49aed1cb54a7a0712a1b29674fb6f4f10f
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
