-- =====================================================================
-- Migration 004: SIAP + International Faculty Mobility Plan tables
-- Applies to live smarttrack_db (system_core schema)
-- =====================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS system_core.siap_internships (
    internship_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_name VARCHAR(150) NOT NULL,
    student_id_no VARCHAR(50),
    email VARCHAR(150),
    college_id INTEGER NOT NULL
        REFERENCES system_core.colleges(college_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    program VARCHAR(150),
    major VARCHAR(150),
    fhe_name VARCHAR(255),
    fhe_address VARCHAR(300),
    departure_date DATE,
    arrival_ph_date DATE,
    flight_details TEXT,
    status VARCHAR(30) DEFAULT 'Not Started'
        CONSTRAINT chk_siap_status
        CHECK (status IN ('Not Started','Started','Ongoing','Completed')),
    internship_start DATE,
    internship_end DATE,
    milestone TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_siap_college ON system_core.siap_internships(college_id);

COMMENT ON TABLE system_core.siap_internships IS
    'Student Internship Abroad Program - admin-managed; students have no login accounts';
COMMENT ON COLUMN system_core.siap_internships.fhe_name IS 'Foreign Host Establishment';
COMMENT ON COLUMN system_core.siap_internships.arrival_ph_date IS 'Arrival back in the Philippines';

CREATE TABLE IF NOT EXISTS system_core.mobility_plans (
    plan_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE
        REFERENCES system_core.users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    preferred_mobility_types TEXT,
    target_country VARCHAR(100),
    preferred_period VARCHAR(150),
    funding_needed BOOLEAN DEFAULT TRUE,
    funding_type VARCHAR(50),
    readiness_status VARCHAR(20) DEFAULT 'Interested'
        CONSTRAINT chk_readiness_status
        CHECK (readiness_status IN ('Interested','Preparing','Ready')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE system_core.mobility_plans IS
    'International Faculty Mobility Plan - faculty interest/readiness for equitable opportunity distribution';

COMMIT;
