# Database Migration Guide

This guide explains how to apply all migrations to your Supabase database using the provided migration script.

## Prerequisites

1. **PostgreSQL Client**: Make sure `psql` is installed on your system
   ```bash
   # On macOS with Homebrew
   brew install postgresql
   
   # On Ubuntu/Debian
   sudo apt-get install postgresql-client
   
   # On CentOS/RHEL
   sudo yum install postgresql
   ```

2. **Supabase Project**: You need a Supabase project with database access

## Setup

### 1. Create .env File

Create a `.env` file in the project root with your Supabase credentials:

```bash
# Database connection string for Supabase PostgreSQL
# Format: postgresql://postgres:[password]@[host]:[port]/postgres
DATABASE_URL=postgresql://postgres:your_password@db.your_project.supabase.co:5432/postgres

# Supabase project URL
SUPABASE_URL=https://your_project.supabase.co

# Supabase anonymous key (anon/public key)
SUPABASE_ANON_KEY=your_supabase_anon_key

# Optional: Backend server port (defaults to 5002)
BACKEND_PORT=5002

# OAuth Configuration (Optional)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_REDIRECT_URL=http://localhost:5002/api/v1/auth/google/callback

MICROSOFT_CLIENT_ID=your_microsoft_client_id
MICROSOFT_CLIENT_SECRET=your_microsoft_client_secret
MICROSOFT_REDIRECT_URL=http://localhost:5002/api/v1/auth/microsoft/callback
MICROSOFT_TENANT_ID=common

APPLE_CLIENT_ID=your_apple_client_id
APPLE_CLIENT_SECRET=your_apple_client_secret
APPLE_REDIRECT_URL=http://localhost:5002/api/v1/auth/apple/callback
```

### 2. Get Your Supabase Credentials

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **Database**
4. Copy the **Connection string** and replace `[YOUR-PASSWORD]` with your actual password
5. Go to **Settings** → **API** to get your **Project URL** and **anon/public key**

## Usage

### Basic Migration (Apply all migrations)

```bash
./migrate.sh
```

This will:
- Load environment variables from `.env`
- Test the database connection
- Apply all migrations in the correct order
- Show a summary of created tables

### Fresh Start (Drop all tables and reapply migrations)

```bash
./migrate.sh --fresh
```

⚠️ **WARNING**: This will drop ALL tables, sequences, functions, and types in the public schema before applying migrations. Use with caution!

### Help

```bash
./migrate.sh --help
```

## Migration Order

The script applies migrations in the following order:

1. `000_supabase_setup.sql` - Sets up Supabase infrastructure (functions, extensions)
2. `001_create_tenants_table.sql` - Creates the tenants table
3. `002_create_token_blacklist.sql` - Creates token blacklist for auth
4. `101_create_person_tables.sql` - Creates person-related tables
5. `201_create_jobs_tables.sql` - Creates job management tables
6. `301_create_orders_tables.sql` - Creates order management tables
7. `401_create_item_tables.sql` - Creates item management tables
8. `402_create_asset_tables.sql` - Creates asset management tables
9. `403_create_machine_tables.sql` - Creates machine management tables

## What the Script Does

1. **Dependency Check**: Verifies that `psql` is installed
2. **Environment Loading**: Loads and validates environment variables from `.env`
3. **Connection Test**: Tests the database connection before proceeding
4. **Optional Fresh Start**: Drops all existing tables if `--fresh` flag is used
5. **Migration Application**: Applies each migration file in sequence
6. **Result Display**: Shows all created tables and their owners
7. **Error Handling**: Stops on any error and provides helpful error messages

## Troubleshooting

### Common Issues

1. **"psql not found"**
   - Install PostgreSQL client tools (see Prerequisites)

2. **"Failed to connect to database"**
   - Check your `DATABASE_URL` in `.env`
   - Ensure your Supabase project is running
   - Verify your password is correct

3. **"Permission denied"**
   - Make sure the script is executable: `chmod +x migrate.sh`

4. **Migration fails**
   - Check the specific migration file mentioned in the error
   - Ensure you're not trying to create tables that already exist (use `--fresh` for a clean start)

### Getting Database Connection Info

You can find your database connection details in Supabase:

1. Dashboard → Settings → Database
2. Look for "Connection string" section
3. Choose "URI" format for the `DATABASE_URL`

### Checking Migration Status

After running migrations, you can verify the tables were created by connecting to your database:

```bash
psql "$DATABASE_URL" -c "\dt"
```

This will list all tables in your database.

## Security Notes

- Never commit your `.env` file to version control
- Use strong passwords for your database
- Consider using environment-specific `.env` files for different deployments
- The script requires your database password, so ensure you're running it in a secure environment 