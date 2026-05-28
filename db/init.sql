-- ============================================
-- MAALEM PROJECT - Schéma de Base de Données
-- Version 2.0
-- ============================================

-- 1. GROUPES DE CATÉGORIES
CREATE TABLE IF NOT EXISTS category_groups (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO category_groups (name) VALUES
    ('Bâtiment & Travaux'),
    ('Techniques & Maison'),
    ('Finition & Décoration'),
    ('Jardinage & Extérieur')
ON CONFLICT (name) DO NOTHING;

-- 2. SPÉCIALITÉS
CREATE TABLE IF NOT EXISTS specialties (
    id          SERIAL PRIMARY KEY,
    group_id    INTEGER NOT NULL REFERENCES category_groups(id) ON DELETE CASCADE,
    name        VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO specialties (group_id, name) VALUES
    -- Bâtiment & Travaux (group_id = 1)
    (1, 'Plomberie'),
    (1, 'Maçonnerie'),
    (1, 'Plâtrerie / Staff'),
    (1, 'Étanchéité'),
    (1, 'Isolation thermique & phonique'),
    (1, 'Démolition'),
    (1, 'Rénovation générale'),
    -- Techniques & Maison (group_id = 2)
    (2, 'Électricité'),
    (2, 'Climatisation'),
    (2, 'Domotique'),
    (2, 'Réparation électroménager'),
    (2, 'Installation TV / Satellite'),
    (2, 'Panneaux solaires'),
    -- Finition & Décoration (group_id = 3)
    (3, 'Peinture'),
    (3, 'Carrelage'),
    (3, 'Menuiserie'),
    (3, 'Serrurerie'),
    -- Jardinage & Extérieur (group_id = 4)
    (4, 'Jardinage'),
    (4, 'Nettoyage')
ON CONFLICT (name) DO NOTHING;

-- 3. USERS
CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    full_name     VARCHAR(150) NOT NULL,
    email         VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role          VARCHAR(20) NOT NULL CHECK (role IN ('client', 'artisan')),
    phone         VARCHAR(20),
    city          VARCHAR(100),
    neighborhood  VARCHAR(100),
    latitude      DOUBLE PRECISION,
    longitude     DOUBLE PRECISION,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Test Users (password: Test1234!)
-- Hash: $2b$10$TYiN7LfvZd4WrYKiR2vvgeZ1bIv/IBmWKX6j8zF7hj7ZZ.MG1fDVm (bcrypt)
INSERT INTO users (full_name, email, password_hash, role, phone, city, neighborhood)
VALUES
    ('Ahmed Test Client', 'ahmed@test.com', '$2b$10$TYiN7LfvZd4WrYKiR2vvgeZ1bIv/IBmWKX6j8zF7hj7ZZ.MG1fDVm', 'client', '0612345678', 'Casablanca', 'Centre'),
    ('Fatima Test Artisan', 'fatima@test.com', '$2b$10$TYiN7LfvZd4WrYKiR2vvgeZ1bIv/IBmWKX6j8zF7hj7ZZ.MG1fDVm', 'artisan', '0698765432', 'Rabat', 'Agdal')
ON CONFLICT (email) DO NOTHING;


-- 4. PROFILS ARTISANS
CREATE TABLE IF NOT EXISTS artisan_profiles (
    user_id        INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    specialty_id   INTEGER REFERENCES specialties(id),
    description    TEXT,
    hourly_rate    DECIMAL(10,2),
    is_available   BOOLEAN DEFAULT TRUE,
    profile_photo_url TEXT,
    cin_url        TEXT,
    cin_verified   BOOLEAN DEFAULT FALSE,
    average_rating DECIMAL(3,2) DEFAULT 0.00
);
-- Link artisan to Plumbing specialty
INSERT INTO artisan_profiles (user_id, specialty_id, hourly_rate, is_available, description, average_rating)
SELECT u.id, s.id, 150.00, true, 'Plombier experimente avec 10 ans d''experience', 4.5
FROM users u, specialties s
WHERE u.email = 'fatima@test.com' AND s.name = 'Plomberie'
ON CONFLICT (user_id) DO NOTHING;


-- 5. WALLETS (un par artisan)
CREATE TABLE IF NOT EXISTS wallets (
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance    DECIMAL(10,2) DEFAULT 0.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. TRANSACTIONS
CREATE TABLE IF NOT EXISTS transactions (
    id               SERIAL PRIMARY KEY,
    wallet_id        INTEGER NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    amount           DECIMAL(10,2) NOT NULL,
    type             VARCHAR(20) NOT NULL 
                     CHECK (type IN ('recharge', 'commission', 'refund')),
    description      TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. BOOKINGS
CREATE TABLE IF NOT EXISTS bookings (
    id             SERIAL PRIMARY KEY,
    client_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artisan_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_date   TIMESTAMP NOT NULL,
    status         VARCHAR(20) DEFAULT 'pending'
                   CHECK (status IN ('pending','accepted','rejected','completed','cancelled')),
    description    TEXT,
    agreed_price   DECIMAL(10,2),
    commission_pct DECIMAL(5,2) DEFAULT 10.00,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. REVIEWS
CREATE TABLE IF NOT EXISTS reviews (
    id         SERIAL PRIMARY KEY,
    booking_id INTEGER UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    client_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artisan_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating     INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. MESSAGES
CREATE TABLE IF NOT EXISTS messages (
    id         SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    sender_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content    TEXT NOT NULL,
    timestamp  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. COMPLAINTS
CREATE TABLE IF NOT EXISTS complaints (
    id          SERIAL PRIMARY KEY,
    booking_id  INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    client_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artisan_id  INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    status      VARCHAR(20) DEFAULT 'open'
                CHECK (status IN ('open', 'in_progress', 'resolved')),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger 1 : Mettre à jour average_rating après chaque avis
CREATE OR REPLACE FUNCTION update_average_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE artisan_profiles
    SET average_rating = (
        SELECT ROUND(AVG(rating)::NUMERIC, 2)
        FROM reviews
        WHERE artisan_id = NEW.artisan_id
    )
    WHERE user_id = NEW.artisan_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_rating
AFTER INSERT OR UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_average_rating();

-- Trigger 2 : Créer un wallet automatiquement pour chaque artisan
CREATE OR REPLACE FUNCTION create_wallet_for_artisan()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'artisan' THEN
        INSERT INTO wallets (user_id) VALUES (NEW.id)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_create_wallet
AFTER INSERT ON users
FOR EACH ROW EXECUTE FUNCTION create_wallet_for_artisan();