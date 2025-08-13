# build image
FROM rust:latest@sha256:5fa1490d5cd16725196511190baad604ddebedcd6e52f1036de46a1a75c85bce AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:377ddc2a20fe8632a49b69dcfff10fccbd5b4f0b8c2d593420a6a5e03070dfa1
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
