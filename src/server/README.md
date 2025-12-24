# Enterprise Management Suite (EMS) Server - Rust

[![Rust](https://github.com/shishir-dey/ems-server-rs/actions/workflows/rust.yml/badge.svg)](https://github.com/shishir-dey/ems-server-rs/actions/workflows/rust.yml)

A multi-tenant Enterprise Management Suite server built with Rust, Axum, and Diesel ORM, connected to Supabase PostgreSQL.

## Features

- **Multi-tenant Architecture**: Complete tenant isolation with Row Level Security (RLS)
- **Person Management**: Four person types (Internal, Customer, Vendor, Distributor)
- **Job Management**: Three job types (Manufacturing, QA, Service) with type-specific data
- **Diesel ORM Integration**: Type-safe database queries with PostgreSQL
- **Supabase Database**: Cloud PostgreSQL with built-in security features
- **Supabase Authentication**: Integrated auth with JWT tokens and refresh tokens
- **RESTful API**: Clean API design with comprehensive validation
- **Type-safe**: Full Rust type safety from database to API responses
- **Comprehensive CRUD**: Complete Create, Read, Update, Delete operations for all entities
- **Job History**: Audit trail for job status changes and operations

## Technology Stack

- **Framework**: Axum (async web framework)
- **ORM**: Diesel (with async support)
- **Database**: Supabase PostgreSQL
- **Authentication**: Supabase Auth + JWT tokens
- **Validation**: Validator crate
- **Serialization**: Serde
- **HTTP Client**: Reqwest (for Supabase API calls)
- **Password Hashing**: BCrypt
- **Testing**: Tokio test framework



## Project Structure

```
src/
├── main.rs              # Application entry point
├── schema.rs            # Diesel database schema
├── models/              # Data models and structures
│   ├── mod.rs
│   ├── auth.rs          # Authentication models
│   ├── tenant.rs        # Tenant models with Diesel derives
│   ├── person.rs        # Person models with Diesel derives
│   ├── job.rs           # Job models with Diesel derives
│   └── token_blacklist.rs # Token blacklist models
├── routes/              # API route handlers
│   ├── mod.rs
│   ├── auth.rs          # Authentication endpoints
│   ├── tenants.rs       # Tenant management endpoints
│   ├── person.rs        # Person management endpoints
│   └── job.rs           # Job management endpoints
├── services/            # Business logic layer
│   ├── mod.rs
│   ├── database.rs      # Diesel database service
│   ├── auth.rs          # Authentication service
│   ├── tenant.rs        # Tenant service
│   ├── person.rs        # Person service with Diesel queries
│   └── job.rs           # Job service with Diesel queries
├── middleware/          # Custom middleware
│   ├── mod.rs
│   ├── tenant.rs        # Tenant context middleware
│   └── auth.rs          # Authentication middleware
└── utils/               # Utility functions
    ├── mod.rs
    ├── auth.rs          # JWT and password utilities
    └── errors.rs        # Custom error types

src/bin/
└── migrate.rs           # Database migration binary for Supabase

migrations/              # Database migrations (SQL files)
├── 000_supabase_setup.sql
├── 001_create_tenants_table.sql
├── 002_create_token_blacklist.sql
├── 101_create_person_tables.sql
├── 201_create_jobs_tables.sql
├── 301_create_orders_tables.sql
├── 401_create_item_tables.sql
├── 402_create_asset_tables.sql
└── 403_create_machine_tables.sql
```

## Getting Started

### Prerequisites

- Rust 1.70+ installed
- Supabase account and project
- PostgreSQL database (via Supabase)
- Diesel CLI (for migrations): `cargo install diesel_cli --features postgres`

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ems-server-rs
```

2. Install dependencies:
```bash
cargo build
```

3. Set up environment variables:
```bash
cp .env.example .env
```

Edit `.env` with your configuration:
```env
# Server Configuration
PORT=5000

# Database Configuration (Supabase PostgreSQL)
DATABASE_URL=postgresql://[username]:[password]@[host]:[port]/[database]?sslmode=require

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here

# Environment
RUST_LOG=info

# Optional: For development
RUST_BACKTRACE=1
```

4. Run the database migrations:

Using the built-in migration binary (recommended):
```bash
# Apply all migrations to Supabase
cargo run --bin migrate

# For a fresh start (drops all tables first)
cargo run --bin migrate -- --fresh

# Get help
cargo run --bin migrate --help
```

Or using Diesel CLI directly:
```bash
# The migrations are already created in the migrations/ folder
# Run them against your Supabase database:
diesel migration run
```

**Note**: The migration binary (`cargo run --bin migrate`) is recommended as it:
- Loads credentials from `.env` automatically
- Applies migrations in the correct order for Supabase
- Includes proper error handling and validation
- Provides a fresh start option for development
- Is written in Rust for consistency with the project

The key migrations create:
- `tenants` table for multi-tenant support
- `person` table for core person data
- `tenant_person` table for many-to-many relationships with roles
- Type-specific person tables: `internal_person`, `customer_person`, `vendor_person`, `distributor_person`
- `jobs` table for core job information
- Type-specific job tables: `manufacturing_job`, `qa_job`, `service_job`
- `job_history` table for audit trail
- `token_blacklist` table for authentication security
- RLS policies for complete tenant isolation
- Indexes for optimal performance

5. Run the application:
```bash
cargo run
```

The server will start on `http://localhost:5000`

## Diesel ORM Integration

This project uses Diesel ORM for type-safe database interactions:

### Key Features:
- **Type Safety**: All database queries are checked at compile time
- **Async Support**: Uses `diesel-async` for non-blocking database operations
- **Connection Pooling**: BB8 connection pool for efficient database connections
- **Tenant Context**: Automatic tenant isolation using PostgreSQL RLS
- **Transaction Support**: Full ACID compliance with transaction handling

### Database Schema:
The schema is automatically generated and maintained in `src/schema.rs`. Key tables include:

- `tenants`: Multi-tenant support
- `person`: Core person information  
- `tenant_person`: Many-to-many with roles
- `internal_person`, `customer_person`, `vendor_person`, `distributor_person`: Type-specific person data
- `jobs`: Core job information
- `manufacturing_job`, `qa_job`, `service_job`: Type-specific job data
- `job_history`: Audit trail for job operations
- `token_blacklist`: Authentication security



## Development

### Running Tests
```bash
cargo test
```

### Database Migrations
```bash
# Create a new migration
diesel migration generate migration_name

# Run migrations
diesel migration run

# Rollback migrations
diesel migration revert
```

### Code Generation
```bash
# Generate schema from database
diesel print-schema > src/schema.rs
```

## Multi-Tenant Architecture

### Tenant Isolation
- **Row Level Security (RLS)**: Database-level tenant isolation
- **Tenant Context**: Automatic tenant context setting for all queries
- **Header-based**: Tenant identification via `X-Tenant-ID` header
- **Secure**: No cross-tenant data access possible

### Tenant Management
- Create, read, update, delete tenants
- Tenant-specific settings and configuration
- Subdomain-based tenant identification

## Error Handling

The application uses comprehensive error handling:
- **Validation Errors**: Request validation with detailed messages
- **Database Errors**: Proper error propagation from Diesel
- **Authentication Errors**: JWT and permission-based errors
- **Tenant Errors**: Tenant context and isolation errors

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request
