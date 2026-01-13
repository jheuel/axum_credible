# build image
FROM rust:latest@sha256:1417b7faaabd8547ecd3c43f98fc5bd7f06295a40935bdbb81240210f7127f76 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:f6681102cd18b4c0c4720a77b602498f4bdcf701c8fc02776dfb0d4c350c381f
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
