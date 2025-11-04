# build image
FROM rust:latest@sha256:a2d7edb8d58e216f3c81ce2d9704ddf00d6b3fd2d55039be9f90ed8b62d8bb3b AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:e0249870a90044494c01e74fbfc8b77ab14e6f47cece844d1e1737f7828a7e1e
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
