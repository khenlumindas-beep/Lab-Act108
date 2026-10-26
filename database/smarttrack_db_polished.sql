/*
================================================================================
  SMARTTRACK: AI-Based International Travel Monitoring System
  IT 108 - Laboratory Activity 2
  
  Database: smarttrack_db
  Schema: system_core
  
  This script creates the complete database schema for tracking international
  faculty travels, documents, and notifications for CSUCC institutions.
================================================================================
*/

-- ============================================================================
-- PART I: DATABASE & SCHEMA CREATION
-- ============================================================================

-- Step 1: Create Database
CREATE DATABASE smarttrack_db
    WITH
    ENCODING = 'UTF8'
    LOCALE = 'en_US.UTF-8'
    TEMPLATE = 'template0';

COMMENT ON DATABASE smarttrack_db IS 
'SmartTrack Database - AI-Based International Travel Monitoring System';

-- Step 2: Create Schema (Execute this after connecting to smarttrack_db)
CREATE SCHEMA system_core
    AUTHORIZATION postgres;

COMMENT ON SCHEMA system_core IS
'Core system schema for SmartTrack application';


-- ============================================================================
-- PART II: CREATE TABLES WITH CONSTRAINTS
-- ============================================================================

-- Table 1: COLLEGES
-- Purpose: Store institutional college information
CREATE TABLE system_core.colleges (
    college_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    code VARCHAR(20) 
        UNIQUE NOT NULL
        CONSTRAINT chk_college_code_length CHECK (LENGTH(code) >= 2),
    name VARCHAR(255) 
        NOT NULL,
    dean_name VARCHAR(150),
    created_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL
);

CREATE INDEX idx_colleges_code ON system_core.colleges(code);

COMMENT ON TABLE system_core.colleges IS 'Institution college information';
COMMENT ON COLUMN system_core.colleges.code IS 'Unique college identifier code (e.g., CEIT, CTHM)';
COMMENT ON COLUMN system_core.colleges.name IS 'Full college name';


-- Table 2: DEPARTMENTS
-- Purpose: Store department information linked to colleges
CREATE TABLE system_core.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    college_id INTEGER 
        NOT NULL
        REFERENCES system_core.colleges(college_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    code VARCHAR(50) 
        NOT NULL,
    name VARCHAR(255),
    CONSTRAINT unique_dept_per_college UNIQUE (college_id, code)
);

CREATE INDEX idx_departments_college_id ON system_core.departments(college_id);
CREATE INDEX idx_departments_code ON system_core.departments(code);

COMMENT ON TABLE system_core.departments IS 'Department information per college';
COMMENT ON COLUMN system_core.departments.code IS 'Department code (can be same across colleges)';


-- Table 3: USERS
-- Purpose: Store faculty and admin user information
CREATE TABLE system_core.users (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    full_name VARCHAR(150) 
        NOT NULL
        CONSTRAINT chk_full_name_not_empty CHECK (LENGTH(TRIM(full_name)) > 0),
    email VARCHAR(150) 
        UNIQUE NOT NULL
        CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%'),
    password_hash VARCHAR(255) 
        NOT NULL,
    role VARCHAR(20) 
        NOT NULL
        CHECK (role IN ('super_admin', 'faculty')),
    college_id INTEGER 
        REFERENCES system_core.colleges(college_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    department_id INTEGER 
        REFERENCES system_core.departments(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    designation VARCHAR(150),
    academic_rank VARCHAR(100),
    contact_number VARCHAR(20),
    is_active BOOLEAN 
        DEFAULT TRUE
        NOT NULL,
    created_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL
);

CREATE INDEX idx_users_email ON system_core.users(email);
CREATE INDEX idx_users_role ON system_core.users(role);
CREATE INDEX idx_users_college_id ON system_core.users(college_id);

COMMENT ON TABLE system_core.users IS 'Faculty and administrator users';
COMMENT ON COLUMN system_core.users.role IS 'User role: super_admin or faculty';
COMMENT ON COLUMN system_core.users.contact_number IS 'Emergency contact number for travels';


-- Table 4: TRAVELS
-- Purpose: Store international travel information
CREATE TABLE system_core.travels (
    travel_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    user_id INTEGER 
        NOT NULL
        REFERENCES system_core.users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    college_id INTEGER 
        NOT NULL
        REFERENCES system_core.colleges(college_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    department_id INTEGER 
        REFERENCES system_core.departments(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    participant_type VARCHAR(20) 
        NOT NULL DEFAULT 'Faculty'
        CONSTRAINT chk_participant_type 
        CHECK (participant_type IN ('Faculty', 'Student')),
    participant_name VARCHAR(150),
    student_id_no VARCHAR(50),
    program VARCHAR(150),
    event_title VARCHAR(500) 
        NOT NULL
        CONSTRAINT chk_event_title_not_empty CHECK (LENGTH(TRIM(event_title)) > 0),
    mobility_type VARCHAR(100) 
        NOT NULL
        CONSTRAINT chk_mobility_type 
        CHECK (mobility_type IN (
            'Faculty Exchange', 'Teaching Mobility', 'Research Mobility',
            'International Training', 'International Conference',
            'Visiting Professorship/Scholarship', 'Fellowship',
            'Short-Term Study Program', 'International Collaborative Research',
            'International Community Extension Engagement', 'International Benchmarking',
            'Other'
        )),
    role_in_event VARCHAR(150),
    start_date DATE 
        NOT NULL,
    end_date DATE 
        NOT NULL
        CONSTRAINT chk_date_range CHECK (end_date >= start_date),
    location VARCHAR(300),
    country VARCHAR(100),
    funding_type VARCHAR(50) 
        CHECK (funding_type IN ('Fully Funded', 'Partially Funded', 'Self-Funded', 'No Funding Required', 'To Be Determined')),
    timeline_pct NUMERIC(5,2) 
        DEFAULT 0
        CHECK (timeline_pct >= 0 AND timeline_pct <= 100),
    timeline_status VARCHAR(20) 
        DEFAULT 'Upcoming'
        CHECK (timeline_status IN ('Upcoming', 'Ongoing', 'Completed', 'Cancelled')),
    mobility_duration VARCHAR(50)
        CONSTRAINT chk_mobility_duration
        CHECK (mobility_duration IS NULL OR mobility_duration IN (
            'Short-Term', 'Medium-Term', 'Long-Term',
            'One Academic Term/Semester', 'One Academic Year'
        )),
    movs TEXT,
    pre_travel_status VARCHAR(50)
        CONSTRAINT chk_pre_travel_status
        CHECK (pre_travel_status IS NULL OR pre_travel_status IN (
            'Not Requested', 'Requested', 'Ongoing',
            'Complete Documents', 'Incomplete Documents', 'No Submission'
        )),
    post_travel_status VARCHAR(50)
        CONSTRAINT chk_post_travel_status
        CHECK (post_travel_status IS NULL OR post_travel_status IN (
            'Not Submitted', 'Submitted Travel Report',
            'Incomplete Documents', 'Ongoing'
        )),
    doc_completeness VARCHAR(50) 
        DEFAULT 'No Submission',
    risk_flag VARCHAR(20) 
        DEFAULT 'Medium'
        CHECK (risk_flag IN ('Low', 'Medium', 'High')),
    follow_up VARCHAR(255)
        CONSTRAINT chk_follow_up
        CHECK (follow_up IS NULL OR follow_up IN ('Done', 'Not Yet', 'Ongoing')),
    remarks TEXT,
    risk_score DOUBLE PRECISION,
    is_active BOOLEAN 
        DEFAULT TRUE
        NOT NULL,
    created_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL,
    updated_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL
);

CREATE INDEX idx_travels_user_id ON system_core.travels(user_id);
CREATE INDEX idx_travels_college_id ON system_core.travels(college_id);
CREATE INDEX idx_travels_timeline_status ON system_core.travels(timeline_status);
CREATE INDEX idx_travels_country ON system_core.travels(country);

COMMENT ON TABLE system_core.travels IS 'International travel records for faculty';
COMMENT ON COLUMN system_core.travels.risk_flag IS 'ML-computed risk level';
COMMENT ON COLUMN system_core.travels.timeline_pct IS 'ML-computed completion percentage';


-- Table 5: DOCUMENTS
-- Purpose: Store travel-related document information
CREATE TABLE system_core.documents (
    document_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    travel_id INTEGER 
        NOT NULL
        REFERENCES system_core.travels(travel_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    doc_type VARCHAR(100) 
        NOT NULL,
    doc_category VARCHAR(50) 
        CHECK (doc_category IN ('Pre-Travel', 'Post-Travel')),
    file_name VARCHAR(255),
    file_path VARCHAR(500) 
        NOT NULL
        CONSTRAINT chk_file_path_not_empty CHECK (LENGTH(TRIM(file_path)) > 0),
    file_size INTEGER 
        CHECK (file_size > 0),
    status VARCHAR(50) 
        DEFAULT 'Pending'
        CHECK (status IN ('Pending', 'Uploaded', 'Verified', 'Incomplete', 'Missing')),
    verified_by INTEGER 
        REFERENCES system_core.users(user_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    verified_at TIMESTAMP,
    uploaded_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL
);

CREATE INDEX idx_documents_travel_id ON system_core.documents(travel_id);
CREATE INDEX idx_documents_status ON system_core.documents(status);

COMMENT ON TABLE system_core.documents IS 'Travel-related documents (TA, TO, Invitations, Reports)';
COMMENT ON COLUMN system_core.documents.doc_category IS 'Pre-Travel or Post-Travel documents';
COMMENT ON COLUMN system_core.documents.status IS 'Document verification status';


-- Table: SIAP INTERNSHIPS
-- Purpose: Student Internship Abroad Program (admin-managed; students have no login)
CREATE TABLE system_core.siap_internships (
    internship_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    student_name VARCHAR(150) 
        NOT NULL,
    student_id_no VARCHAR(50),
    email VARCHAR(150),
    college_id INTEGER 
        NOT NULL
        REFERENCES system_core.colleges(college_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    program VARCHAR(150),
    major VARCHAR(150),
    fhe_name VARCHAR(255),
    fhe_address VARCHAR(300),
    departure_date DATE,
    arrival_ph_date DATE,
    flight_details TEXT,
    status VARCHAR(30) 
        DEFAULT 'Not Started'
        CONSTRAINT chk_siap_status 
        CHECK (status IN ('Not Started','Started','Ongoing','Completed')),
    internship_start DATE,
    internship_end DATE,
    milestone TEXT,
    notes TEXT,
    created_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL,
    updated_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL
);

CREATE INDEX idx_siap_college ON system_core.siap_internships(college_id);

COMMENT ON TABLE system_core.siap_internships IS 'Student Internship Abroad Program - admin-managed';
COMMENT ON COLUMN system_core.siap_internships.fhe_name IS 'Foreign Host Establishment';
COMMENT ON COLUMN system_core.siap_internships.arrival_ph_date IS 'Arrival back in the Philippines';


-- Table: MOBILITY PLANS
-- Purpose: International Faculty Mobility Plan (faculty interest + equitable distribution)
CREATE TABLE system_core.mobility_plans (
    plan_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    user_id INTEGER 
        NOT NULL
        UNIQUE
        REFERENCES system_core.users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    preferred_mobility_types TEXT,
    target_country VARCHAR(100),
    preferred_period VARCHAR(150),
    funding_needed BOOLEAN 
        DEFAULT TRUE,
    funding_type VARCHAR(50),
    readiness_status VARCHAR(20) 
        DEFAULT 'Interested'
        CONSTRAINT chk_readiness_status 
        CHECK (readiness_status IN ('Interested','Preparing','Ready')),
    notes TEXT,
    created_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL,
    updated_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL
);

COMMENT ON TABLE system_core.mobility_plans IS 'International Faculty Mobility Plan';


-- Table 6: NOTIFICATIONS
-- Purpose: Store user notifications for travel updates
CREATE TABLE system_core.notifications (
    notification_id INTEGER GENERATED ALWAYS AS IDENTITY 
        PRIMARY KEY,
    user_id INTEGER 
        NOT NULL
        REFERENCES system_core.users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    travel_id INTEGER 
        REFERENCES system_core.travels(travel_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    title VARCHAR(255),
    message TEXT,
    type VARCHAR(50) 
        DEFAULT 'info'
        CHECK (type IN ('info', 'warning', 'approval', 'deadline', 'system')),
    is_read BOOLEAN 
        DEFAULT FALSE
        NOT NULL,
    created_at TIMESTAMP 
        DEFAULT CURRENT_TIMESTAMP
        NOT NULL
);

CREATE INDEX idx_notifications_user_id ON system_core.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON system_core.notifications(is_read);

COMMENT ON TABLE system_core.notifications IS 'User notifications for travel updates';
COMMENT ON COLUMN system_core.notifications.type IS 'Notification category';


-- ============================================================================
-- PART III: ALTER TABLE OPERATIONS
-- ============================================================================

-- ALTER 1: Add contact number column to users (already added above)
-- This was included in the initial CREATE TABLE definition

-- ALTER 2: Modify event_title column length
-- This was set to VARCHAR(500) in the initial CREATE TABLE definition

-- ALTER 3: Add UNIQUE constraint on department code per college
-- This was added as: CONSTRAINT unique_dept_per_college UNIQUE (college_id, code)
-- in the initial CREATE TABLE definition


-- ============================================================================
-- PART IV: INSERT OPERATIONS - SAMPLE DATA
-- ============================================================================

-- Insert Colleges (5 CSUCC colleges)
INSERT INTO system_core.colleges (code, name, dean_name) 
VALUES
    ('CEIT', 'College of Engineering and Information Technology', 'Dr. Vicardo J. Aroy'),
    ('CTHM', 'College of Tourism and Hospitality Management', 'Dr. Maria Santos'),
    ('CBA', 'College of Business and Accountancy', 'Dr. Bocarie T. Sultan'),
    ('CIT', 'College of Industrial Technology', 'Dr. Ramon Reyes'),
    ('CTE', 'College of Teacher Education', 'Dr. Elena Cruz')
ON CONFLICT (code) DO NOTHING;


-- Insert Departments
INSERT INTO system_core.departments (college_id, code, name) 
VALUES
    (1, 'CITTE-DTE', 'Department of Teacher Education'),
    (1, 'CITTE-DIT', 'Department of Information Technology'),
    (1, 'CEIT-BSCpE', 'BS Computer Engineering'),
    (1, 'CEPRIC', 'CEIT Research and Innovation Center'),
    (2, 'CTHM-DHM', 'Department of Hospitality Management'),
    (2, 'CTHM-TM', 'Department of Tourism Management'),
    (3, 'CBA-BSA', 'BS Accountancy'),
    (3, 'CBA-BSBA', 'BS Business Administration'),
    (4, 'CIT-DIT', 'Department of Industrial Technology'),
    (5, 'CTE-ELEM', 'Elementary Education'),
    (5, 'CTE-SEC', 'Secondary Education')
ON CONFLICT (college_id, code) DO NOTHING;


-- Insert Users (2 Super Admins + 5 Faculty)
INSERT INTO system_core.users 
(full_name, email, password_hash, role, college_id, department_id, designation, academic_rank, contact_number) 
VALUES
    ('OIGE Admin One', 'oige@csucc.edu.ph', '$2b$12$hash1', 'super_admin', NULL, NULL, 'OIGE Director', NULL, '+63-9171234567'),
    ('ILMO Admin Two', 'ilmo@csucc.edu.ph', '$2b$12$hash2', 'super_admin', NULL, NULL, 'ILMO Coordinator', NULL, '+63-9179876543'),
    ('Dr. Ritchfildjay L. Mariscal', 'rlmariscal@csucc.edu.ph', '$2b$12$hash3', 'faculty', 1, 1, 'Division Chief for Admin and Finance', 'Associate Professor', '+63-9171111111'),
    ('Ms. Marisol Jane M. Beray', 'mmberay@csucc.edu.ph', '$2b$12$hash4', 'faculty', 1, 1, 'Head, OCID', 'Assistant Professor', '+63-9172222222'),
    ('Mr. John O. Estillore', 'joestillore@csucc.edu.ph', '$2b$12$hash5', 'faculty', 1, 1, 'Faculty', 'Instructor', '+63-9173333333'),
    ('Prof. Maria Jovita C. Serrano', 'mcserrano@csucc.edu.ph', '$2b$12$hash6', 'faculty', 2, 5, 'Head, OIGE', 'Professor', '+63-9174444444'),
    ('Dr. Bocarie T. Sultan', 'btsultan@csucc.edu.ph', '$2b$12$hash7', 'faculty', 3, 7, 'Dean, CBA', 'Professor', '+63-9175555555')
ON CONFLICT (email) DO NOTHING;


-- Insert Travel Records with RETURNING clause
INSERT INTO system_core.travels 
(user_id, college_id, department_id, event_title, mobility_type, role_in_event, 
 start_date, end_date, location, country, funding_type) 
VALUES
    (3, 1, 1, '1st International Conference on Education and Society (ICES 2025)', 
     'International Conference', 'Presenter', '2025-01-19', '2025-01-28', 
     'University of Aizu', 'Japan', 'Fully Funded')
RETURNING travel_id, user_id, event_title, country;


-- Insert Additional Travel Records
INSERT INTO system_core.travels 
(user_id, college_id, department_id, event_title, mobility_type, role_in_event,
 start_date, end_date, location, country, funding_type, timeline_pct, timeline_status,
 mobility_duration, doc_completeness, risk_flag, follow_up, remarks) 
VALUES
    (4, 1, 1, 'Tatung University 2025 Summer School - Photovoltaic Workshop',
     'International Training', 'Attendee', '2025-06-16', '2025-06-27',
     'Tatung University, Taipei', 'Taiwan', 'Fully Funded',
     100, 'Completed', 'Short-Term', 'Complete', 'Low', 'Done', 'All documents submitted'),
    
    (5, 1, 1, '13th International Conference on Multidisciplinary Research',
     'International Conference', 'Presenter', '2025-11-03', '2025-11-08',
     'Vietnamese-German University', 'Vietnam', 'Partially Funded',
     100, 'Completed', 'Short-Term', 'Incomplete', 'Medium', 'Not Yet', 'Travel report pending'),
    
    (6, 2, 5, '3rd Faculty Development Program',
     'International Training', 'Attendee', '2024-04-21', '2024-04-25',
     'Bangkok and Pattaya', 'Thailand', 'Fully Funded',
     100, 'Completed', 'Short-Term', 'Complete', 'Low', 'Done', 'All documents submitted'),
    
    (7, 3, 7, '11th International STEM Education Conference',
     'International Conference', 'Presenter', '2026-07-15', '2026-07-17',
     'Chiang Mai', 'Thailand', 'Fully Funded',
     0, 'Upcoming', 'Short-Term', 'Incomplete', 'High', 'Not Yet', 'Travel upcoming')
ON CONFLICT DO NOTHING;


-- Insert Documents
INSERT INTO system_core.documents 
(travel_id, doc_type, doc_category, file_name, file_path, file_size, status) 
VALUES
    (1, 'Travel Authority', 'Pre-Travel', 'ICES2025_TA.pdf', './uploads/2025/travel_1_TA.pdf', 245000, 'Verified'),
    (1, 'Travel Order', 'Pre-Travel', 'ICES2025_TO.pdf', './uploads/2025/travel_1_TO.pdf', 198000, 'Verified'),
    (1, 'Invitation Letter', 'Pre-Travel', 'ICES2025_Invitation.pdf', './uploads/2025/travel_1_invitation.pdf', 320000, 'Verified'),
    (2, 'Travel Report', 'Post-Travel', 'TU2025_Report.pdf', './uploads/2025/travel_2_report.pdf', 450000, 'Verified'),
    (3, 'Travel Report', 'Post-Travel', 'ICMR13_Report.pdf', './uploads/2025/travel_3_report.pdf', 380000, 'Pending'),
    (4, 'Travel Authority', 'Pre-Travel', 'FDP_TA.pdf', './uploads/2024/travel_4_TA.pdf', 210000, 'Verified')
ON CONFLICT DO NOTHING;


-- Insert Notifications
INSERT INTO system_core.notifications (user_id, travel_id, title, message, type) 
VALUES
    (3, 1, 'Travel Completed', 'Your travel to Japan has been marked as completed.', 'info'),
    (4, 2, 'Documents Verified', 'All your documents for Taiwan Summer School have been verified.', 'approval'),
    (5, 3, 'Missing Document', 'Please upload your Travel Report for ICMR13.', 'warning'),
    (6, 4, 'Upcoming Travel', 'Your travel to Thailand starts in 7 days. Prepare documents.', 'deadline'),
    (7, 5, 'Document Pending', 'Your pre-travel documents are still pending verification.', 'warning')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- PART V: READ OPERATIONS - SELECT QUERIES
-- ============================================================================

-- SELECT 1: Display all colleges
SELECT 
    college_id,
    code,
    name,
    dean_name,
    created_at
FROM system_core.colleges
ORDER BY college_id;


-- SELECT 2: Display user information
SELECT 
    user_id,
    full_name,
    email,
    role,
    designation,
    is_active
FROM system_core.users
ORDER BY full_name;


-- SELECT 3: Filter completed travels
SELECT 
    travel_id,
    event_title,
    country,
    timeline_status,
    doc_completeness
FROM system_core.travels
WHERE timeline_status = 'Completed'
ORDER BY travel_id;


-- SELECT 4: Sort travels by start date
SELECT 
    travel_id,
    event_title,
    start_date,
    end_date,
    country,
    risk_flag
FROM system_core.travels
ORDER BY start_date DESC;


-- SELECT 5: Join query - Faculty travels to Japan with complete documentation
SELECT 
    t.travel_id,
    u.full_name AS faculty_name,
    u.designation,
    t.event_title,
    t.country,
    t.doc_completeness,
    t.risk_flag,
    t.timeline_status
FROM system_core.travels t
INNER JOIN system_core.users u ON t.user_id = u.user_id
WHERE t.country = 'Japan' 
  AND t.doc_completeness = 'Complete'
ORDER BY t.travel_id;


-- ============================================================================
-- PART VI: UPDATE OPERATIONS WITH RETURNING CLAUSE
-- ============================================================================

-- UPDATE 1: Change travel status to Ongoing
UPDATE system_core.travels 
SET 
    timeline_status = 'Ongoing',
    timeline_pct = 50,
    updated_at = CURRENT_TIMESTAMP
WHERE travel_id = 5
RETURNING travel_id, event_title, timeline_status, timeline_pct, updated_at;


-- UPDATE 2: Verify a document
UPDATE system_core.documents 
SET 
    status = 'Verified',
    verified_by = 1,
    verified_at = CURRENT_TIMESTAMP
WHERE document_id = 5
RETURNING document_id, travel_id, doc_type, status, verified_at;


-- UPDATE 3: Update faculty designation
UPDATE system_core.users 
SET 
    designation = 'Division Chief for Research and Extension'
WHERE user_id = 3
RETURNING user_id, full_name, designation;


-- ============================================================================
-- PART VII: DELETE OPERATIONS WITH RETURNING CLAUSE
-- ============================================================================

-- DELETE 1: Delete temporary notification
DELETE FROM system_core.notifications 
WHERE title = 'Test Notification'
RETURNING notification_id, user_id, title, created_at;


-- DELETE 2: Delete cancelled travel
DELETE FROM system_core.travels 
WHERE event_title = 'Cancelled Conference'
RETURNING travel_id, event_title, timeline_status;


-- ============================================================================
-- PART VIII: CONSTRAINT VALIDATION TESTS (Documentation Only)
-- ============================================================================

/*
Test 1: UNIQUE Constraint Violation
-----------------------------------
Command:
  INSERT INTO system_core.users (full_name, email, password_hash, role) 
  VALUES ('Duplicate User', 'rlmariscal@csucc.edu.ph', 'hash', 'faculty');

Expected Error:
  ERROR: duplicate key value violates unique constraint "users_email_key"
  DETAIL: Key (email)=(rlmariscal@csucc.edu.ph) already exists.

Explanation:
  The email column has a UNIQUE constraint. Attempting to insert a duplicate
  email address violates this constraint, preventing data duplication.


Test 2: NOT NULL Constraint Violation
--------------------------------------
Command:
  INSERT INTO system_core.travels 
  (user_id, college_id, mobility_type, start_date, end_date) 
  VALUES (3, 1, 'International Conference', '2026-01-01', '2026-01-05');

Expected Error:
  ERROR: null value in column "event_title" violates not-null constraint
  DETAIL: Failing row contains (..., null, ...).

Explanation:
  The event_title column is NOT NULL. Cannot insert a travel record without
  specifying the event title.


Test 3: FOREIGN KEY Constraint Violation
------------------------------------------
Command:
  INSERT INTO system_core.travels 
  (user_id, college_id, event_title, mobility_type, start_date, end_date) 
  VALUES (999, 1, 'Test Event', 'International Conference', '2026-01-01', '2026-01-05');

Expected Error:
  ERROR: insert or update on table "travels" violates foreign key constraint "travels_user_id_fkey"
  DETAIL: Key (user_id)=(999) is not present in table "users".

Explanation:
  The user_id column references the users table (FOREIGN KEY). User ID 999
  does not exist, violating referential integrity. This ensures data consistency
  across related tables.


Test 4: CHECK Constraint Violation
-----------------------------------
Command:
  INSERT INTO system_core.travels 
  (user_id, college_id, event_title, mobility_type, start_date, end_date, funding_type) 
  VALUES (3, 1, 'Test Event', 'International Conference', '2026-01-01', '2026-01-05', 'Invalid Funding');

Expected Error:
  ERROR: new row for relation "travels" violates check constraint "travels_funding_type_check"
  DETAIL: Failing row contains (..., Invalid Funding, ...).

Explanation:
  The funding_type column has a CHECK constraint that only allows specific values:
  'Fully Funded', 'Partially Funded', 'Self-Funded', 'No Funding Required', or 'To Be Determined'.
  The value 'Invalid Funding' does not match any allowed value.
*/

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
COMMIT;
