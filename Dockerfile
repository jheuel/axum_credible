# build image
FROM rust:latest@sha256:640960fe15de2f67cc88db7f0f547977cb759cba9eab246df29d98d02aaf24b8 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:88f88a2b8bd1873876a2ff15df523a66602aa57177e24b5f22064c4886ec398a
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
