# build image
FROM rust:latest@sha256:3329e2de3e9ff2d58da56e95ef99a3180a4e76336a676f3fe2b88f0b0d6bcfbf AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:8810492a2dd16b7f59239c1e0cc1e56c1a1a5957d11f639776bd6798e795608b
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
