# build image
FROM rust:latest@sha256:80302520b7199f0504975bca59a914015e9fee088f759875dbbc238ca9509ee1 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:4448d44b91bf4a13cb1b4e02d9d5f87ed40621d6e33f0ae7b6ddf71d57e29364
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
