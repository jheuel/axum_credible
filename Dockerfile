# build image
FROM rust:latest@sha256:976303ceda00c5f21d6fe97500927285c7e0f6a2e8df71ae18a6c8e9b37550a1 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:d6743b7859c917a488ca39f4ab5e174011305f50b44ce32d3b9ea5d81b291b3b
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
