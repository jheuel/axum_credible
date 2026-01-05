# build image
FROM rust:latest@sha256:65734d21f103d104fe0d9e508a424f7f60abd10e489d36de8bd36ae6c80e746d AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:449673e1239be6fdc89616f926abb87f360c280c3bb7ca3591694564359695fa
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
