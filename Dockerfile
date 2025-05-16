# build image
FROM rust:latest@sha256:db94dde5e0436c6e45877340a8f829e07705593c319bd223e24ea026b35c0249 AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:88f88a2b8bd1873876a2ff15df523a66602aa57177e24b5f22064c4886ec398a
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
