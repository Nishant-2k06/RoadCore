-- RoadCore PostgreSQL + PostGIS Initialization Script
-- Project: RoadCore Intelligent Toll Integrity Platform

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. ENUM TYPES
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('ADMIN', 'GOVERNMENT', 'ENFORCEMENT', 'TRAVELLER');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE user_status AS ENUM ('ACTIVE', 'SUSPENDED', 'PENDING');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE journey_status AS ENUM ('IN_PROGRESS', 'COMPLETED', 'FLAGGED_REVIEW', 'INSUFFICIENT_EVIDENCE', 'CLOSED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transaction_status AS ENUM ('PENDING', 'CHARGED', 'FAILED', 'DISPUTED', 'WAIVED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE alert_severity AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE alert_status AS ENUM ('OPEN', 'UNDER_INVESTIGATION', 'RESOLVED', 'DISMISSED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE case_status AS ENUM ('NEW', 'IN_REVIEW', 'ENFORCEMENT_ISSUED', 'DISMISSED', 'APPEALED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE appeal_status AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'ACCEPTED', 'REJECTED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. USERS
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'TRAVELLER',
    status user_status NOT NULL DEFAULT 'ACTIVE',
    phone VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. GANTRIES
CREATE TABLE IF NOT EXISTS gantries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    highway VARCHAR(100) NOT NULL,
    km_marker NUMERIC(8, 2) NOT NULL,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    location GEOGRAPHY(Point, 4326),
    direction VARCHAR(50) NOT NULL,
    health_status VARCHAR(50) NOT NULL DEFAULT 'OPERATIONAL',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. VEHICLES
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    color VARCHAR(50),
    make_model VARCHAR(100),
    registered_owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    fastag_id VARCHAR(100) UNIQUE,
    attributes JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. OBSERVATIONS
CREATE TABLE IF NOT EXISTS observations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gantry_id UUID NOT NULL REFERENCES gantries(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    plate_text VARCHAR(20),
    plate_confidence NUMERIC(5, 4) NOT NULL,
    vehicle_type VARCHAR(50),
    vehicle_color VARCHAR(50),
    reid_embedding JSONB,
    reid_confidence NUMERIC(5, 4),
    frame_image_uri VARCHAR(500) NOT NULL,
    plate_crop_uri VARCHAR(500),
    sha256_hash CHAR(64) NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. JOURNEYS
CREATE TABLE IF NOT EXISTS journeys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    entry_gantry_id UUID NOT NULL REFERENCES gantries(id),
    exit_gantry_id UUID REFERENCES gantries(id),
    entry_time TIMESTAMPTZ NOT NULL,
    exit_time TIMESTAMPTZ,
    distance_km NUMERIC(8, 2) NOT NULL DEFAULT 0.00,
    duration_minutes NUMERIC(8, 2),
    average_speed_kmh NUMERIC(8, 2),
    toll_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    status journey_status NOT NULL DEFAULT 'IN_PROGRESS',
    evidence_status VARCHAR(50) DEFAULT 'NORMAL',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. JOURNEY SEGMENTS
CREATE TABLE IF NOT EXISTS journey_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
    from_gantry UUID NOT NULL REFERENCES gantries(id),
    to_gantry UUID NOT NULL REFERENCES gantries(id),
    distance_km NUMERIC(8, 2) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    speed_kmh NUMERIC(8, 2) NOT NULL,
    validation_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. TOLL TRANSACTIONS
CREATE TABLE IF NOT EXISTS toll_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    journey_id UUID NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    amount NUMERIC(10, 2) NOT NULL,
    base_rate_per_km NUMERIC(6, 2) NOT NULL,
    vehicle_class_multiplier NUMERIC(4, 2) NOT NULL DEFAULT 1.00,
    transaction_status transaction_status NOT NULL DEFAULT 'PENDING',
    payment_reference VARCHAR(100),
    e_notice_issued BOOLEAN DEFAULT FALSE,
    e_notice_id VARCHAR(100),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. ALERTS
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    journey_id UUID REFERENCES journeys(id) ON DELETE SET NULL,
    alert_type VARCHAR(100) NOT NULL,
    confidence NUMERIC(5, 4) NOT NULL,
    severity alert_severity NOT NULL DEFAULT 'MEDIUM',
    status alert_status NOT NULL DEFAULT 'OPEN',
    description TEXT NOT NULL,
    evidence_payload JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. CASES
CREATE TABLE IF NOT EXISTS cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_number VARCHAR(100) UNIQUE NOT NULL,
    vehicle_id UUID REFERENCES vehicles(id),
    journey_id UUID REFERENCES journeys(id),
    alert_id UUID REFERENCES alerts(id),
    case_type VARCHAR(100) NOT NULL,
    status case_status NOT NULL DEFAULT 'NEW',
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    investigator_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. EVIDENCE
CREATE TABLE IF NOT EXISTS evidence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
    observation_id UUID REFERENCES observations(id) ON DELETE SET NULL,
    asset_uri VARCHAR(500) NOT NULL,
    sha256_hash CHAR(64) NOT NULL,
    evidence_type VARCHAR(50) NOT NULL,
    captured_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. APPEALS
CREATE TABLE IF NOT EXISTS appeals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
    traveller_id UUID NOT NULL REFERENCES users(id),
    reason TEXT NOT NULL,
    traveller_proof_uri VARCHAR(500),
    status appeal_status NOT NULL DEFAULT 'SUBMITTED',
    reviewed_by UUID REFERENCES users(id),
    reviewer_decision_notes TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ
);

-- 13. AUDIT LOGS
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(100) NOT NULL,
    ip_address VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. PERFORMANCE & GEOSPATIAL INDEXES
CREATE INDEX IF NOT EXISTS idx_observations_timestamp ON observations(timestamp);
CREATE INDEX IF NOT EXISTS idx_observations_plate ON observations(plate_text);
CREATE INDEX IF NOT EXISTS idx_observations_vehicle_id ON observations(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_observations_gantry_id ON observations(gantry_id);
CREATE INDEX IF NOT EXISTS idx_journeys_vehicle_id ON journeys(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_journeys_status ON journeys(status);
CREATE INDEX IF NOT EXISTS idx_gantries_location ON gantries USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_alerts_status_severity ON alerts(status, severity);
CREATE INDEX IF NOT EXISTS idx_cases_status ON cases(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(created_at);
