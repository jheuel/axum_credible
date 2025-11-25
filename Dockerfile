# build image
FROM rust:latest@sha256:4a29b0db5c961cd530f39276ece3eb6e66925b59599324c8c19723b72a423615 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:7cb087f19bcc175b96fbe4c2aef42ed00733a659581a80f6ebccfd8fe3185a3d
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
