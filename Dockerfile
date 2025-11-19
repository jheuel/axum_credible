# build image
FROM rust:latest@sha256:638747aac515b4b346c144d8f8debfc367e3a89ba62383df72a184c4b9e31313 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:7cb087f19bcc175b96fbe4c2aef42ed00733a659581a80f6ebccfd8fe3185a3d
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
