# Enterprise Management Suite (EMS)

[![CI](https://github.com/shishir-dey/ems/actions/workflows/ci.yml/badge.svg)](https://github.com/shishir-dey/ems/actions/workflows/ci.yml) [![CD](https://github.com/shishir-dey/ems/actions/workflows/cd.yml/badge.svg)](https://github.com/shishir-dey/ems/actions/workflows/cd.yml)

A modern, multi-tenant Enterprise Management Suite for hardware manufacturing. Built with Rust backend and React frontend.

## Tech Stack

- **Backend**: Rust + Axum + Diesel + PostgreSQL
- **Frontend**: React + TypeScript + Tailwind CSS + Vite
- **Database**: Supabase PostgreSQL with Row Level Security
- **Authentication**: Supabase Auth with JWT tokens

## Features

- **Multi-tenant Architecture**: Complete tenant isolation
- **Person Management**: Internal, Customer, Vendor, and Distributor types
- **Job Management**: Manufacturing, QA, and Service jobs
- **RESTful API**: Type-safe with comprehensive validation
- **Modern UI**: Responsive design with accessible components

## Project Structure

```
├── src/
│   ├── client/          # React frontend
│   └── server/          # Rust backend
├── config.env          # Environment configuration
├── run.py              # Unified development script
├── load-env.sh         # Environment loader (Unix/macOS)
└── load-env.bat        # Environment loader (Windows)
```

## Quick Start

### Prerequisites
- Node.js 18+ and npm
- Rust 1.70+ and Cargo
- Python 3.7+ and pip
- Supabase account

### Setup

1. **Clone and setup**
   ```bash
   git clone <repository-url>
   cd ems
   pip install -r requirements.txt
   python run.py setup
   ```

2. **Configure environment**
   ```bash
   # Edit config.env with your Supabase credentials
   # File is auto-created from config.env.example
   ```

3. **Setup database**
   ```bash
   cd src/server
   cargo install diesel_cli --features postgres
   diesel migration run
   ```

4. **Start development**
   ```bash
   # Load environment
   source load-env.sh        # Unix/macOS
   load-env.bat load          # Windows
   
   # Start servers
   python run.py dev
   ```
   
   ## Development Commands

### Unified Script (run.py)

| Command | Description | Options |
|---------|-------------|---------|
| `python run.py setup` | Setup development environment | |
| `python run.py dev` | Start development servers | `--frontend-only`, `--backend-only` |
| `python run.py build` | Build frontend and backend | `--frontend-only`, `--backend-only`, `--release` |
| `python run.py test` | Run all tests | `--frontend-only`, `--backend-only` |
| `python run.py lint` | Lint code | `--frontend-only`, `--backend-only`, `--fix` |
| `python run.py format` | Format code | `--frontend-only`, `--backend-only` |
| `python run.py clean` | Clean build artifacts | `--frontend-only`, `--backend-only`, `--deep` |
| `python run.py status` | Show component status | |

### Environment Loaders

| Command | Description |
|---------|-------------|
| `source load-env.sh` | Load environment (Unix/macOS) |
| `load-env.bat load` | Load environment (Windows) |

### Direct Commands

| Component | Command |
|-----------|---------|
| Frontend dev | `cd src/client && npm start` |
| Backend dev | `cd src/server && cargo run` |
| Frontend test | `cd src/client && npm test` |
| Backend test | `cd src/server && cargo test` |

## Deployment

The project includes Docker support and CI/CD pipelines for automated deployment to Digital Ocean.

## Additional Documentation

- [Client Documentation](https://github.com/shishir-dey/ems-client-react)
- [Server Documentation](https://github.com/shishir-dey/ems-server-rs)
