CREATE TABLE IF NOT EXISTS food_users (
 id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 name text NOT NULL, email text NOT NULL UNIQUE, digest text NOT NULL,
 merchant boolean NOT NULL DEFAULT false
);
CREATE TABLE IF NOT EXISTS food_sessions (
 token_hash text PRIMARY KEY, user_id integer NOT NULL REFERENCES food_users, expires timestamptz NOT NULL
);
CREATE TABLE IF NOT EXISTS food_orders (
 id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 user_id integer NOT NULL REFERENCES food_users, request_id uuid NOT NULL, quantity integer NOT NULL CHECK(quantity BETWEEN 1 AND 20),
 extras text[] NOT NULL, address text NOT NULL, payment text NOT NULL CHECK(payment IN ('Pix','Cartão')),
 total integer NOT NULL, status text NOT NULL DEFAULT 'Recebido', created timestamptz NOT NULL DEFAULT now(),
 UNIQUE(user_id,request_id)
);

CREATE TABLE IF NOT EXISTS food_auth_limits (bucket text PRIMARY KEY, expires timestamptz NOT NULL, attempts integer NOT NULL DEFAULT 1);
