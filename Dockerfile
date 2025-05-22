# build image
FROM rust:latest@sha256:893a03d96de2c0e6eb8b73e24b2266264b6dee244ce997d1bae246901093ba23 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:b3ef39b8a45ee3b689c462dfa711454bcfc9c9965fe81c6cfb7ff4029b5b8cd7
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
