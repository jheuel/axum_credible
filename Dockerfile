# build image
FROM rust:latest@sha256:eabb786e74b520e7ea45baca03ea20c3e8c6dc037c392d457badf05d8e5818b5 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:0c80836db6d5bd1f89ed3c1300bbd888fc8a415130a52fd86e501ce38471fe5b
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
