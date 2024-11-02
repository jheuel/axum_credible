CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    actor_id BLOB NOT NULL,
    kind TEXT NOT NULL,
    url TEXT NOT NULL,
    referrer TEXT,
    search TEXT,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE actors (
    id BLOB NOT NULL PRIMARY KEY,
    country TEXT,
    city TEXT,
    user_agent_id INTEGER,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    category TEXT,
    os TEXT,
    os_version TEXT,
    browser_type TEXT,
    version TEXT,
    vendor TEXT
)
