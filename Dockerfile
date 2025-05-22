# build image
FROM rust:latest@sha256:5e33ae75f40bf25854fa86e33487f47075016d16726355a72171f67362ad6bf7 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:b3ef39b8a45ee3b689c462dfa711454bcfc9c9965fe81c6cfb7ff4029b5b8cd7
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
