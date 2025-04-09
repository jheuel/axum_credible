# build image
FROM rust:latest@sha256:7b65306dd21304f48c22be08d6a3e41001eef738b3bd3a5da51119c802321883 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:00a24d7c50ebe46934e31f6154c0434e2ab51259a65e028be42413c636385f7f
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
