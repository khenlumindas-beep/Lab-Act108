-- ============================================================
-- SMARTTRACK: AI-Based International Travel Monitoring System
-- IT 108 - Laboratory Activity 2
-- ============================================================

-- IV. CREATE DATABASE
CREATE DATABASE smarttrack_db;

-- V. CREATE SCHEMA
-- Note: Execute database creation first, then connect to smarttrack_db before running remaining scripts
CREATE SCHEMA system_core;

-- ============================================================
-- CREATE TABLES
-- ============================================================

-- Table: colleges
CREATE TABLE system_core.colleges (
    college_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    dean_name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: departments
CREATE TABLE system_core.departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    college_id INTEGER NOT NULL REFERENCES system_core.colleges(college_id),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255)
);

-- Table: users
CREATE TABLE system_core.users (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('super_admin', 'faculty')),
    college_id INTEGER REFERENCES system_core.colleges(college_id),
    department_id INTEGER REFERENCES system_core.departments(department_id),
    designation VARCHAR(150),
    academic_rank VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: travels
CREATE TABLE system_core.travels (
    travel_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES system_core.users(user_id),
    college_id INTEGER NOT NULL REFERENCES system_core.colleges(college_id),
    department_id INTEGER REFERENCES system_core.departments(department_id),
    event_title VARCHAR(300) NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    role_in_event VARCHAR(150),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    location VARCHAR(300),
    country VARCHAR(100),
    funding_type VARCHAR(50) CHECK (funding_type IN ('Fully Funded', 'Partially Funded', 'Self-Funded', 'No Funding Required', 'To Be Determined')),
    timeline_pct NUMERIC(5,2) DEFAULT 0,
    timeline_status VARCHAR(20) DEFAULT 'Upcoming' CHECK (timeline_status IN ('Upcoming', 'Ongoing', 'Completed', 'Cancelled')),
    mobility_duration VARCHAR(50),
    doc_completeness VARCHAR(50) DEFAULT 'No Submission',
    risk_flag VARCHAR(20) DEFAULT 'Medium' CHECK (risk_flag IN ('Low', 'Medium', 'High')),
    follow_up VARCHAR(255),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: documents
CREATE TABLE system_core.documents (
    document_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    travel_id INTEGER NOT NULL REFERENCES system_core.travels(travel_id) ON DELETE CASCADE,
    doc_type VARCHAR(100) NOT NULL,
    doc_category VARCHAR(50) CHECK (doc_category IN ('Pre-Travel', 'Post-Travel')),
    file_name VARCHAR(255),
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    status VARCHAR(50) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Uploaded', 'Verified', 'Incomplete', 'Missing')),
    verified_by INTEGER REFERENCES system_core.users(user_id),
    verified_at TIMESTAMP,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: notifications
CREATE TABLE system_core.notifications (
    notification_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES system_core.users(user_id),
    travel_id INTEGER REFERENCES system_core.travels(travel_id) ON DELETE CASCADE,
    title VARCHAR(255),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info' CHECK (type IN ('info', 'warning', 'approval', 'deadline', 'system')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- XI. ALTER TABLE EXERCISES (3 operations)
-- ============================================================

-- ALTER 1: Add new column for contact number
ALTER TABLE system_core.users 
ADD COLUMN contact_number VARCHAR(20);

-- Explanation: Added contact_number to store faculty phone numbers 
-- for emergency communication during international travel.

-- ALTER 2: Modify column length for event title
ALTER TABLE system_core.travels 
ALTER COLUMN event_title TYPE VARCHAR(500);

-- Explanation: Increased event_title length to accommodate longer 
-- conference/workshop names that often exceed 300 characters.

-- ALTER 3: Add UNIQUE constraint on department code per college
ALTER TABLE system_core.departments 
ADD CONSTRAINT unique_dept_per_college UNIQUE (college_id, code);

-- Explanation: Prevents duplicate department codes within the same 
-- college while allowing the same code across different colleges.

-- ============================================================
-- XII. INSERT OPERATIONS
-- ============================================================

-- ============================================================
-- INSERT: Colleges (5 CSUCC colleges)
-- ============================================================
INSERT INTO system_core.colleges (code, name, dean_name) VALUES
('CEIT', 'College of Engineering and Information Technology', 'Dr. Vicardo J. Aroy'),
('CTHM', 'College of Tourism and Hospitality Management', 'Dr. Maria Santos'),
('CBA',  'College of Business and Accountancy', 'Dr. Bocarie T. Sultan'),
('CIT',  'College of Industrial Technology', 'Dr. Ramon Reyes'),
('CTE',  'College of Teacher Education', 'Dr. Elena Cruz');

-- ============================================================
-- INSERT: Departments
-- ============================================================
INSERT INTO system_core.departments (college_id, code, name) VALUES
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
(5, 'CTE-SEC', 'Secondary Education');

-- ============================================================
-- INSERT: Users (2 Super Admins + 5 Faculty)
-- ============================================================
INSERT INTO system_core.users 
(full_name, email, password_hash, role, college_id, department_id, designation, academic_rank, contact_number) 
VALUES
('OIGE Admin One', 'oige@csucc.edu.ph', '$2b$12$hash1', 'super_admin', NULL, NULL, 'OIGE Director', NULL, '+63-9171234567'),
('ILMO Admin Two', 'ilmo@csucc.edu.ph', '$2b$12$hash2', 'super_admin', NULL, NULL, 'ILMO Coordinator', NULL, '+63-9179876543'),
('Dr. Ritchfildjay L. Mariscal', 'rlmariscal@csucc.edu.ph', '$2b$12$hash3', 'faculty', 1, 1, 'Division Chief for Admin and Finance', 'Associate Professor', '+63-9171111111'),
('Ms. Marisol Jane M. Beray', 'mmberay@csucc.edu.ph', '$2b$12$hash4', 'faculty', 1, 1, 'Head, OCID', 'Assistant Professor', '+63-9172222222'),
('Mr. John O. Estillore', 'joestillore@csucc.edu.ph', '$2b$12$hash5', 'faculty', 1, 1, 'Faculty', 'Instructor', '+63-9173333333'),
('Prof. Maria Jovita C. Serrano', 'mcserrano@csucc.edu.ph', '$2b$12$hash6', 'faculty', 2, 5, 'Head, OIGE', 'Professor', '+63-9174444444'),
('Dr. Bocarie T. Sultan', 'btsultan@csucc.edu.ph', '$2b$12$hash7', 'faculty', 3, 7, 'Dean, CBA', 'Professor', '+63-9175555555');

-- ============================================================
-- INSERT with RETURNING (required)
-- ============================================================
INSERT INTO system_core.travels 
(user_id, college_id, department_id, event_title, activity_type, role_in_event, 
 start_date, end_date, location, country, funding_type) 
VALUES
(3, 1, 1, '1st International Conference on Education and Society (ICES 2025)', 
 'Conference', 'Presenter', '2025-01-19', '2025-01-28', 
 'University of Aizu, Japan', 'Japan', 'Fully Funded')
RETURNING *;

-- ============================================================
-- INSERT: More travels
-- ============================================================
INSERT INTO system_core.travels 
(user_id, college_id, department_id, event_title, activity_type, role_in_event,
 start_date, end_date, location, country, funding_type, timeline_pct, timeline_status,
 mobility_duration, doc_completeness, risk_flag, follow_up, remarks) 
VALUES
(4, 1, 1, 'Tatung University 2025 Summer School - Photovoltaic Workshop',
 'Summer School', 'Attendee', '2025-06-16', '2025-06-27',
 'Tatung University, Taipei, Taiwan', 'Taiwan', 'Fully Funded',
 100, 'Completed', 'Short-Term', 'Complete', 'Low', 'None needed', 'All documents submitted'),
(5, 1, 1, '13th International Conference on Multidisciplinary Research',
 'Conference', 'Presenter', '2025-11-03', '2025-11-08',
 'Vietnamese-German University, Vietnam', 'Vietnam', 'Partially Funded',
 100, 'Completed', 'Short-Term', 'Incomplete', 'Medium', 'Request missing travel report', 'Travel report pending'),
(6, 2, 5, '3rd Faculty Development Program',
 'Conference', 'Attendee', '2024-04-21', '2024-04-25',
 'Bangkok and Pattaya, Thailand', 'Thailand', 'Fully Funded',
 100, 'Completed', 'Short-Term', 'Complete', 'Low', 'None needed', 'All documents submitted'),
(7, 3, 7, '11th International STEM Education Conference',
 'Conference', 'Presenter', '2026-07-15', '2026-07-17',
 'Chiang Mai, Thailand', 'Thailand', 'Fully Funded',
 0, 'Upcoming', 'Short-Term', 'Incomplete', 'High', 'Prepare pre-travel documents', 'Travel upcoming');

-- ============================================================
-- INSERT: Documents
-- ============================================================
INSERT INTO system_core.documents 
(travel_id, doc_type, doc_category, file_name, file_path, file_size, status) 
VALUES
(1, 'Travel Authority', 'Pre-Travel', 'ICES2025_TA.pdf', './uploads/2025/travel_1_TA.pdf', 245000, 'Verified'),
(1, 'Travel Order', 'Pre-Travel', 'ICES2025_TO.pdf', './uploads/2025/travel_1_TO.pdf', 198000, 'Verified'),
(1, 'Invitation Letter', 'Pre-Travel', 'ICES2025_Invitation.pdf', './uploads/2025/travel_1_invitation.pdf', 320000, 'Verified'),
(2, 'Travel Report', 'Post-Travel', 'TU2025_Report.pdf', './uploads/2025/travel_2_report.pdf', 450000, 'Verified'),
(3, 'Travel Report', 'Post-Travel', 'ICMR13_Report.pdf', './uploads/2025/travel_3_report.pdf', 380000, 'Pending'),
(4, 'Travel Authority', 'Pre-Travel', 'FDP_TA.pdf', './uploads/2024/travel_4_TA.pdf', 210000, 'Verified');

-- ============================================================
-- INSERT: Notifications
-- ============================================================
INSERT INTO system_core.notifications (user_id, travel_id, title, message, type) VALUES
(3, 1, 'Travel Completed', 'Your travel to Japan has been marked as completed.', 'info'),
(4, 2, 'Documents Verified', 'All your documents for Taiwan Summer School have been verified.', 'approval'),
(5, 3, 'Missing Document', 'Please upload your Travel Report for ICMR13.', 'warning'),
(6, 4, 'Upcoming Travel', 'Your travel to Thailand starts in 7 days. Prepare documents.', 'deadline'),
(7, 5, 'Document Pending', 'Your pre-travel documents are still pending verification.', 'warning');

-- ============================================================
-- XIII. READ OPERATIONS (5 SELECT queries)
-- ============================================================

-- SELECT 1: Display all records from colleges
SELECT * FROM system_core.colleges;

-- SELECT 2: Display selected columns from users
SELECT user_id, full_name, email, role, designation 
FROM system_core.users;

-- SELECT 3: Filter records using WHERE
SELECT travel_id, event_title, country, timeline_status 
FROM system_core.travels 
WHERE timeline_status = 'Completed';

-- SELECT 4: Sort records using ORDER BY
SELECT travel_id, event_title, start_date, country 
FROM system_core.travels 
ORDER BY start_date DESC;

-- SELECT 5: Retrieve records related to important condition
-- (Faculty travels to Japan with complete documents)
SELECT t.travel_id, u.full_name, t.event_title, t.country, t.doc_completeness
FROM system_core.travels t
JOIN system_core.users u ON t.user_id = u.user_id
WHERE t.country = 'Japan' AND t.doc_completeness = 'Complete';

-- ============================================================
-- XIV. UPDATE OPERATIONS (3 updates + RETURNING)
-- ============================================================

-- UPDATE 1: Change travel status
UPDATE system_core.travels 
SET timeline_status = 'Ongoing', timeline_pct = 50
WHERE travel_id = 3
RETURNING *;

-- UPDATE 2: Verify a document
UPDATE system_core.documents 
SET status = 'Verified', verified_by = 1, verified_at = CURRENT_TIMESTAMP
WHERE document_id = 5
RETURNING *;

-- UPDATE 3: Update faculty designation
UPDATE system_core.users 
SET designation = 'Division Chief for Research and Extension'
WHERE user_id = 3
RETURNING *;

-- ============================================================
-- XV. DELETE OPERATIONS (2 deletes + RETURNING)
-- ============================================================

-- First, insert a temporary record for testing
INSERT INTO system_core.notifications (user_id, title, message, type) 
VALUES (3, 'Test Notification', 'This is a temporary notification', 'system');

-- DELETE 1: Delete the temporary notification
DELETE FROM system_core.notifications 
WHERE title = 'Test Notification'
RETURNING *;

-- DELETE 2: Delete a cancelled travel (insert temp first)
INSERT INTO system_core.travels 
(user_id, college_id, event_title, activity_type, start_date, end_date, timeline_status) 
VALUES (3, 1, 'Cancelled Conference', 'Conference', '2026-01-01', '2026-01-05', 'Cancelled')
RETURNING travel_id;

-- Delete the cancelled travel by travel_id
DELETE FROM system_core.travels 
WHERE timeline_status = 'Cancelled'
RETURNING *;

-- ============================================================
-- XVI. CONSTRAINT ERROR ANALYSIS (4 tests)
-- ============================================================

-- Test 1 — Duplicate UNIQUE value
-- SQL Command:
-- INSERT INTO system_core.users (full_name, email, password_hash, role) 
-- VALUES ('Duplicate User', 'rlmariscal@csucc.edu.ph', 'hash', 'faculty');
-- PostgreSQL Error Message:
-- ERROR: duplicate key value violates unique constraint "users_email_key"
-- DETAIL: Key (email)=(rlmariscal@csucc.edu.ph) already exists.
-- Constraint Violated: UNIQUE (email)
-- Explanation: The email already exists in the users table. UNIQUE constraint prevents duplicate emails.

-- Test 2 — Missing NOT NULL value
-- SQL Command:
-- INSERT INTO system_core.travels 
-- (user_id, college_id, activity_type, start_date, end_date) 
-- VALUES (3, 1, 'Conference', '2026-01-01', '2026-01-05');
-- PostgreSQL Error Message:
-- ERROR: null value in column "event_title" violates not-null constraint
-- DETAIL: Failing row contains (..., null, ...).
-- Constraint Violated: NOT NULL (event_title)
-- Explanation: event_title is required. Cannot insert a travel without an event title.

-- Test 3 — Invalid FOREIGN KEY
-- SQL Command:
-- INSERT INTO system_core.travels 
-- (user_id, college_id, event_title, activity_type, start_date, end_date) 
-- VALUES (999, 1, 'Test Event', 'Conference', '2026-01-01', '2026-01-05');
-- PostgreSQL Error Message:
-- ERROR: insert or update on table "travels" violates foreign key constraint "travels_user_id_fkey"
-- DETAIL: Key (user_id)=(999) is not present in table "users".
-- Constraint Violated: FOREIGN KEY (user_id)
-- Explanation: user_id 999 does not exist in users table. Foreign key ensures referential integrity.

-- Test 4 — Invalid CHECK value
-- SQL Command:
-- INSERT INTO system_core.travels 
-- (user_id, college_id, event_title, activity_type, start_date, end_date, funding_type) 
-- VALUES (3, 1, 'Test Event', 'Conference', '2026-01-01', '2026-01-05', 'Invalid Funding');
-- PostgreSQL Error Message:
-- ERROR: new row for relation "travels" violates check constraint "travels_funding_type_check"
-- DETAIL: Failing row contains (..., Invalid Funding, ...).
-- Constraint Violated: CHECK (funding_type IN ('Fully Funded', 'Partially Funded', 'Self-Funded', 'No Funding Required', 'To Be Determined'))
-- Explanation: funding_type must be one of the allowed values. CHECK constraint validates data against predefined list.
