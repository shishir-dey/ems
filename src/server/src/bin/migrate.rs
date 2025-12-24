// Standalone migration binary - doesn't depend on the main library
// to avoid compilation issues with the main project

use std::env;
use std::fs;
use std::path::Path;
use std::process;
use tokio_postgres::{Client, NoTls};

#[tokio::main]
async fn main() {
    // Load environment variables
    if let Err(_) = dotenvy::dotenv() {
        // If .env file doesn't exist, continue anyway
    }

    let args: Vec<String> = env::args().collect();

    // Parse command line arguments
    let mut fresh_start = false;
    let mut show_help = false;

    for arg in &args[1..] {
        match arg.as_str() {
            "--fresh" => fresh_start = true,
            "--help" | "-h" => show_help = true,
            _ => {
                eprintln!("❌ Unknown argument: {}", arg);
                print_help();
                process::exit(1);
            }
        }
    }

    if show_help {
        print_help();
        return;
    }

    println!("🚀 EMS Server Database Migration Tool");
    println!("=====================================");

    // Load and validate environment variables
    let database_url = match env::var("DATABASE_URL") {
        Ok(url) => url,
        Err(_) => {
            eprintln!("❌ DATABASE_URL environment variable is required. Check your .env file.");
            process::exit(1);
        }
    };

    // Connect to database
    println!("📡 Connecting to database...");
    let (client, connection) = match tokio_postgres::connect(&database_url, NoTls).await {
        Ok((client, connection)) => (client, connection),
        Err(e) => {
            eprintln!("❌ Failed to connect to database: {}", e);
            eprintln!("Check your DATABASE_URL in the .env file.");
            process::exit(1);
        }
    };

    // The connection object performs the actual communication with the database,
    // so spawn it off to run on its own.
    tokio::spawn(async move {
        if let Err(e) = connection.await {
            eprintln!("Connection error: {}", e);
        }
    });

    println!("✅ Database connection established");

    // Drop all tables if fresh start is requested
    if fresh_start {
        if let Err(e) = drop_all_tables(&client).await {
            eprintln!("❌ Failed to drop tables: {}", e);
            process::exit(1);
        }
    }

    // Apply migrations
    if let Err(e) = apply_migrations(&client).await {
        eprintln!("❌ Migration failed: {}", e);
        process::exit(1);
    }

    // Show database info
    if let Err(e) = show_database_info(&client).await {
        eprintln!("❌ Failed to show database info: {}", e);
        process::exit(1);
    }

    println!("🎉 Migration completed successfully!");
}

async fn drop_all_tables(client: &Client) -> Result<(), Box<dyn std::error::Error>> {
    println!("⚠️  WARNING: This will DROP ALL TABLES in the database!");

    // Ask for confirmation
    use std::io::{self, Write};
    print!("Are you sure you want to continue? (y/N): ");
    io::stdout().flush().unwrap();

    let mut input = String::new();
    io::stdin().read_line(&mut input).unwrap();

    if !input.trim().to_lowercase().starts_with('y') {
        println!("ℹ️  Operation cancelled");
        process::exit(0);
    }

    println!("🗑️  Dropping all tables, sequences, functions, and types...");

    let drop_sql = r#"
        DO $$ 
        DECLARE 
            r RECORD;
        BEGIN
            -- Drop all tables
            FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
            LOOP
                EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
            END LOOP;
            
            -- Drop all sequences
            FOR r IN (SELECT sequencename FROM pg_sequences WHERE schemaname = 'public')
            LOOP
                EXECUTE 'DROP SEQUENCE IF EXISTS public.' || quote_ident(r.sequencename) || ' CASCADE';
            END LOOP;
            
            -- Drop all functions (except built-in ones)
            FOR r IN (SELECT proname, oidvectortypes(proargtypes) as argtypes
                      FROM pg_proc 
                      INNER JOIN pg_namespace ns ON (pg_proc.pronamespace = ns.oid)
                      WHERE ns.nspname = 'public' AND proname NOT LIKE 'pg_%')
            LOOP
                EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.argtypes || ') CASCADE';
            END LOOP;
            
            -- Drop all types
            FOR r IN (SELECT typname FROM pg_type 
                      INNER JOIN pg_namespace ns ON (pg_type.typnamespace = ns.oid)
                      WHERE ns.nspname = 'public' AND typname NOT LIKE 'pg_%' AND typname NOT LIKE '_%')
            LOOP
                EXECUTE 'DROP TYPE IF EXISTS public.' || quote_ident(r.typname) || ' CASCADE';
            END LOOP;
        END $$;
    "#;

    client
        .execute(drop_sql, &[])
        .await
        .map_err(|e| format!("Failed to drop tables: {}", e))?;

    println!("✅ All tables dropped successfully");
    Ok(())
}

async fn apply_migrations(client: &Client) -> Result<(), Box<dyn std::error::Error>> {
    println!("📁 Loading migration files...");

    // Define migration order explicitly
    let migrations = vec![
        "migrations/000_supabase_setup.sql",
        "migrations/001_create_tenants_table.sql",
        "migrations/101_create_person_tables.sql",
        "migrations/102_create_token_blacklist.sql",
        "migrations/201_create_jobs_tables.sql",
        "migrations/301_create_orders_tables.sql",
        "migrations/401_create_item_tables.sql",
        "migrations/402_create_asset_tables.sql",
        "migrations/403_create_machine_tables.sql",
    ];

    println!("🔄 Applying migrations in order...");

    for migration_file in migrations {
        if Path::new(migration_file).exists() {
            if let Err(e) = apply_single_migration(client, migration_file).await {
                return Err(e);
            }
        } else {
            println!("⚠️  Migration file not found: {}", migration_file);
        }
    }

    println!("✅ All migrations applied successfully!");
    Ok(())
}

async fn apply_single_migration(
    client: &Client,
    migration_file: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let migration_name = Path::new(migration_file)
        .file_stem()
        .unwrap()
        .to_string_lossy();

    println!("  📄 Applying: {}", migration_name);

    let sql = fs::read_to_string(migration_file)
        .map_err(|e| format!("Failed to read migration file {}: {}", migration_file, e))?;

    client
        .batch_execute(&sql)
        .await
        .map_err(|e| format!("Failed to execute migration {}: {}", migration_name, e))?;

    println!("    ✓ {} applied successfully", migration_name);
    Ok(())
}

async fn show_database_info(client: &Client) -> Result<(), Box<dyn std::error::Error>> {
    println!("📊 Database Tables:");
    println!("==================");

    let rows = client
        .query(
            "SELECT schemaname, tablename, tableowner 
             FROM pg_tables 
             WHERE schemaname = 'public' 
             ORDER BY tablename",
            &[],
        )
        .await
        .map_err(|e| format!("Failed to query database tables: {}", e))?;

    if rows.is_empty() {
        println!("No tables found in the public schema.");
    } else {
        println!("{:<25} {:<25} {}", "Schema", "Table", "Owner");
        println!("{:-<75}", "");
        for row in rows {
            let schema: &str = row.get(0);
            let table: &str = row.get(1);
            let owner: &str = row.get(2);
            println!("{:<25} {:<25} {}", schema, table, owner);
        }
    }

    Ok(())
}

fn print_help() {
    println!("🛠️  EMS Server Database Migration Tool");
    println!();
    println!("USAGE:");
    println!("    cargo run --bin migrate [OPTIONS]");
    println!();
    println!("OPTIONS:");
    println!("    --fresh    Drop all tables before applying migrations (fresh start)");
    println!("    --help     Show this help message");
    println!();
    println!("EXAMPLES:");
    println!("    cargo run --bin migrate           # Apply all migrations");
    println!("    cargo run --bin migrate --fresh   # Fresh start (drop all tables)");
    println!();
    println!("REQUIREMENTS:");
    println!("    - .env file with DATABASE_URL set to your Supabase PostgreSQL connection");
    println!("    - Migration files in the migrations/ directory");
    println!();
    println!("ENVIRONMENT VARIABLES:");
    println!("    DATABASE_URL    PostgreSQL connection string for Supabase");
    println!("                   Format: postgresql://postgres:password@host:port/dbname");
}
