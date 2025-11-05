# build image
FROM rust:latest@sha256:087fe682ef35ecac5b110dbf35cafade2cbd487f8a86e9390203f77f962887cf AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:e0249870a90044494c01e74fbfc8b77ab14e6f47cece844d1e1737f7828a7e1e
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
