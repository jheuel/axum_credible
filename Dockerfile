# build image
FROM rust:latest@sha256:6294bac02f47763ab6f462de25c5299179bd84a7c29889ca1114330cb5f0d0c5 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:e0249870a90044494c01e74fbfc8b77ab14e6f47cece844d1e1737f7828a7e1e
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
