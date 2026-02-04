# build image
FROM rust:latest@sha256:e35d0f677e0e0be6f4b4f93bf16e6f93ab4f427dc440a0ef12511026f8b7d7e3 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:4448d44b91bf4a13cb1b4e02d9d5f87ed40621d6e33f0ae7b6ddf71d57e29364
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
