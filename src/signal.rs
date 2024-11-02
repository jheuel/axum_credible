pub async fn shutdown_signal(key_rotate_handle: tokio::task::AbortHandle) {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    let abort = move || {
        key_rotate_handle.abort();
    };

    tokio::select! {
        _ = ctrl_c => { abort() },
        _ = terminate => { abort() },
    }
}
