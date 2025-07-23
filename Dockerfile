# build image
FROM rust:latest@sha256:4f63ef81873422e39cc914de76adbdd58097c0d693e134e163ea9844c0e2ee99 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:377ddc2a20fe8632a49b69dcfff10fccbd5b4f0b8c2d593420a6a5e03070dfa1
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
