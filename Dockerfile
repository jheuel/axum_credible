# build image
FROM rust:latest@sha256:80ccfb51023dbb8bfa7dc469c514a5a66343252d5e7c5aa0fab1e7d82f4ebbdc AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:70b337e820bf51d399fa5bfa96a0066fbf22f3aa2c3307e2401b91e2207ac3c3
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
