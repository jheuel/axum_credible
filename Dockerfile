# build image
FROM rust:latest@sha256:6e6d04bd50cd4c433a805c58c13f186a508c5b5417b9b61cae40ec28e0593c51 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:8810492a2dd16b7f59239c1e0cc1e56c1a1a5957d11f639776bd6798e795608b
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
