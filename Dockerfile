# build image
FROM rust:latest@sha256:eabb786e74b520e7ea45baca03ea20c3e8c6dc037c392d457badf05d8e5818b5 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:d6743b7859c917a488ca39f4ab5e174011305f50b44ce32d3b9ea5d81b291b3b
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
