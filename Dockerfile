# build image
FROM rust:latest@sha256:910b9dc6597a3ef16458dc1d20520714d3526ddb038749b8d87334798064d672 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:449673e1239be6fdc89616f926abb87f360c280c3bb7ca3591694564359695fa
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
