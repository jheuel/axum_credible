# build image
FROM rust:latest@sha256:c5511e7b18c038386e7e1a6580493ab125a8e9474c9717b38fe724e15448aa1e AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:b3ef39b8a45ee3b689c462dfa711454bcfc9c9965fe81c6cfb7ff4029b5b8cd7
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
