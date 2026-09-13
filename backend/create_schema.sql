-- Taskly Database Schema for Supabase / PostgreSQL

CREATE TABLE IF NOT EXISTS users (
	id SERIAL PRIMARY KEY, 
	phone_number VARCHAR UNIQUE, 
	password VARCHAR, 
	full_name VARCHAR, 
	email VARCHAR UNIQUE, 
	user_type VARCHAR, 
	id_number VARCHAR, 
	categories JSON, 
	location_city VARCHAR, 
	location_area VARCHAR, 
	profile_picture_url VARCHAR, 
	cloudinary_id VARCHAR, 
	rating FLOAT DEFAULT 5.0, 
	total_jobs INTEGER DEFAULT 0, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS jobs (
	id SERIAL PRIMARY KEY, 
	title VARCHAR, 
	description TEXT, 
	category VARCHAR, 
	location_city VARCHAR, 
	location_area VARCHAR, 
	location_address VARCHAR, 
	urgency VARCHAR, 
	price FLOAT, 
	recruiter_id INTEGER REFERENCES users(id), 
	recruiter_phone VARCHAR, 
	status VARCHAR DEFAULT 'open', 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wallets (
	id SERIAL PRIMARY KEY, 
	user_id INTEGER REFERENCES users(id), 
	balance FLOAT DEFAULT 0.0, 
	available_withdrawal FLOAT DEFAULT 0.0, 
	total_earned FLOAT DEFAULT 0.0, 
	updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS applications (
	id SERIAL PRIMARY KEY, 
	job_id INTEGER REFERENCES jobs(id), 
	tasker_id INTEGER REFERENCES users(id), 
	tasker_phone VARCHAR, 
	cover_letter VARCHAR, 
	status VARCHAR DEFAULT 'pending', 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transactions (
	id SERIAL PRIMARY KEY, 
	user_id INTEGER REFERENCES users(id), 
	amount FLOAT, 
	type VARCHAR, 
	job_id INTEGER, 
	status VARCHAR DEFAULT 'pending', 
	mpesa_reference VARCHAR, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS work_images (
	id SERIAL PRIMARY KEY, 
	job_id INTEGER REFERENCES jobs(id), 
	uploaded_by VARCHAR, 
	image_url VARCHAR, 
	image_type VARCHAR, 
	cloudinary_id VARCHAR, 
	uploaded_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ratings (
	id SERIAL PRIMARY KEY, 
	job_id INTEGER NOT NULL REFERENCES jobs(id), 
	rater_id INTEGER NOT NULL REFERENCES users(id), 
	ratee_id INTEGER NOT NULL REFERENCES users(id), 
	score INTEGER NOT NULL, 
	comment TEXT, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS disputes (
	id SERIAL PRIMARY KEY, 
	job_id INTEGER NOT NULL REFERENCES jobs(id), 
	opened_by_id INTEGER NOT NULL REFERENCES users(id), 
	reason VARCHAR NOT NULL, 
	description TEXT, 
	status VARCHAR DEFAULT 'open', 
	resolution TEXT, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP, 
	resolved_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE IF NOT EXISTS receipts (
	id SERIAL PRIMARY KEY, 
	receipt_code VARCHAR UNIQUE NOT NULL, 
	job_id INTEGER NOT NULL REFERENCES jobs(id), 
	user_id INTEGER NOT NULL REFERENCES users(id), 
	amount FLOAT NOT NULL, 
	commission_amount FLOAT DEFAULT 0.0, 
	net_amount FLOAT NOT NULL, 
	tax_amount FLOAT DEFAULT 0.0, 
	status VARCHAR DEFAULT 'pending', 
	pdf_url VARCHAR, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP, 
	paid_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE IF NOT EXISTS daily_reports (
	id SERIAL PRIMARY KEY, 
	report_date VARCHAR UNIQUE NOT NULL, 
	total_jobs INTEGER DEFAULT 0, 
	gross_earnings FLOAT DEFAULT 0.0, 
	total_commission FLOAT DEFAULT 0.0, 
	total_tax FLOAT DEFAULT 0.0, 
	net_earnings FLOAT DEFAULT 0.0, 
	pdf_url VARCHAR, 
	sent_to_email BOOLEAN DEFAULT FALSE, 
	sent_at TIMESTAMP WITHOUT TIME ZONE, 
	created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
