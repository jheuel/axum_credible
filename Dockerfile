# build image
FROM rust:latest@sha256:0e18a916cc41ed3a99356ded9b3c8b0f91e15249d4507a18ec9af4edb7a631e5 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:e0249870a90044494c01e74fbfc8b77ab14e6f47cece844d1e1737f7828a7e1e
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
