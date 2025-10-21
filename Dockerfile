# build image
FROM rust:latest@sha256:0741250bea82c52487c6429d21c8d14eb139388e52bf19188cd3b4253332ee9e AS builder
WORKDIR /axum_credible
COPY . .
RUN cargo build --release

# release image
FROM debian:stable-slim@sha256:a771c85b2287eae7ce8fe0a4c2637d575c5d991555ae680c187c5572153648d9
WORKDIR /app
COPY --from=builder /axum_credible/target/release/axum_credible /app/
CMD ["/app/axum_credible"]
