# build image
FROM rust:latest@sha256:ed61687dc6260a43d26b53b19407cf9145bd34d3fd8d6200aac5b7675d2608e1 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:0c80836db6d5bd1f89ed3c1300bbd888fc8a415130a52fd86e501ce38471fe5b
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
