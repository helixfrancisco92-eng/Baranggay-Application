-- ============================================
-- V1: INITIAL DATABASE SCHEMA
-- ============================================

CREATE TABLE IF NOT EXISTS public.admins (
    admin_id BIGINT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL,
    role VARCHAR(30) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.citizens (
    citizen_id BIGINT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    address VARCHAR(255) NOT NULL,
    contact_no VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.document_types (
    document_type_id BIGINT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    processing_days INT NOT NULL DEFAULT 1,
    fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.requirements (
    requirement_id BIGINT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.document_type_requirements (
    document_type_id BIGINT NOT NULL REFERENCES public.document_types(document_type_id) ON DELETE CASCADE,
    requirement_id BIGINT NOT NULL REFERENCES public.requirements(requirement_id) ON DELETE CASCADE,
    is_required BOOLEAN NOT NULL DEFAULT true,
    PRIMARY KEY (document_type_id, requirement_id)
);

CREATE TABLE IF NOT EXISTS public.document_requests (
    request_id BIGINT PRIMARY KEY,
    citizen_id BIGINT NOT NULL REFERENCES public.citizens(citizen_id),
    document_type_id BIGINT NOT NULL REFERENCES public.document_types(document_type_id),
    request_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    purpose VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    remarks TEXT NOT NULL,
    approved_by BIGINT REFERENCES public.admins(admin_id),
    processed_at TIMESTAMP,
    released_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.request_status_history (
    history_id BIGINT PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES public.document_requests(request_id) ON DELETE CASCADE,
    admin_id BIGINT NOT NULL REFERENCES public.admins(admin_id),
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks TEXT
);
