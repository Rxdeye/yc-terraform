CREATE TABLE IF NOT EXISTS users (
   id SERIAL PRIMARY KEY,
   name TEXT NOT NULL,
   created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO users (name) VALUES ('Alice'), ('Bob');



