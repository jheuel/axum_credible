# build image
FROM rust:latest@sha256:6a6dda669f020fa1fcb0903e37a049484fbf4b4699c8cb89db26ca030f475259 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:00a24d7c50ebe46934e31f6154c0434e2ab51259a65e028be42413c636385f7f
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
