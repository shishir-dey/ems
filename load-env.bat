@echo off
setlocal enabledelayedexpansion

:: Enterprise Management Suite (EMS) - Environment Loader (Windows)
:: This script loads environment variables from config.env for local development

:: Get script directory
set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%config.env"

:: Function definitions using labels and goto

:print_header
echo === %~1 ===
goto :eof

:print_success
echo [92m✓ %~1[0m
goto :eof

:print_warning
echo [93m⚠ %~1[0m
goto :eof

:print_error
echo [91m✗ %~1[0m
goto :eof

:command_exists
where "%~1" >nul 2>&1
goto :eof

:validate_env_vars
set "missing_vars="
set "required_vars=DATABASE_URL SUPABASE_URL SUPABASE_ANON_KEY JWT_SECRET"

for %%v in (%required_vars%) do (
    call :get_env_var "%%v" env_value
    if "!env_value!"=="" (
        set "missing_vars=!missing_vars! %%v"
    ) else if "!env_value:your-=!" neq "!env_value!" (
        set "missing_vars=!missing_vars! %%v"
    ) else if "!env_value:example=!" neq "!env_value!" (
        set "missing_vars=!missing_vars! %%v"
    )
)

if not "!missing_vars!"=="" (
    call :print_error "Missing or unconfigured environment variables:"
    for %%v in (%missing_vars%) do (
        call :print_error "  - %%v"
    )
    call :print_error "Please configure these variables in config.env"
    exit /b 1
)

exit /b 0

:get_env_var
set "%~2=!%~1!"
goto :eof

:load_environment
if not exist "%CONFIG_FILE%" (
    call :print_error "Configuration file not found: %CONFIG_FILE%"
    
    if exist "%SCRIPT_DIR%config.env.example" (
        call :print_warning "Found config.env.example. Creating config.env..."
        copy "%SCRIPT_DIR%config.env.example" "%CONFIG_FILE%" >nul
        call :print_success "Config file created from template"
        call :print_warning "Please edit config.env with your actual configuration values"
        exit /b 1
    ) else (
        call :print_error "config.env.example not found either"
        exit /b 1
    )
)

call :print_header "Loading Environment Configuration"

set "loaded_count=0"
for /f "usebackq tokens=1,2 delims== eol=#" %%a in ("%CONFIG_FILE%") do (
    if not "%%a"=="" if not "%%b"=="" (
        :: Remove quotes from value
        set "var_name=%%a"
        set "var_value=%%b"
        set "var_value=!var_value:"=!"
        set "var_value=!var_value:'=!"
        
        :: Remove leading/trailing spaces
        for /f "tokens=* delims= " %%x in ("!var_name!") do set "var_name=%%x"
        for /f "tokens=* delims= " %%x in ("!var_value!") do set "var_value=%%x"
        
        :: Set the environment variable
        set "!var_name!=!var_value!"
        set /a loaded_count+=1
    )
)

call :print_success "Loaded %loaded_count% environment variables from config.env"

:: Validate critical environment variables
call :validate_env_vars
if errorlevel 1 (
    exit /b 1
) else (
    call :print_success "All required environment variables are configured"
    exit /b 0
)

:show_env_status
call :print_header "Environment Status"

:: Check Node.js
call :command_exists "node"
if errorlevel 1 (
    call :print_warning "Node.js not found"
) else (
    for /f "tokens=*" %%i in ('node --version 2^>nul') do (
        call :print_success "Node.js: %%i"
    )
)

:: Check npm
call :command_exists "npm"
if errorlevel 1 (
    call :print_warning "npm not found"
) else (
    for /f "tokens=*" %%i in ('npm --version 2^>nul') do (
        call :print_success "npm: %%i"
    )
)

:: Check Rust
call :command_exists "rustc"
if errorlevel 1 (
    call :print_warning "Rust not found"
) else (
    for /f "tokens=*" %%i in ('rustc --version 2^>nul') do (
        call :print_success "Rust: %%i"
    )
)

:: Check Cargo
call :command_exists "cargo"
if errorlevel 1 (
    call :print_warning "Cargo not found"
) else (
    for /f "tokens=*" %%i in ('cargo --version 2^>nul') do (
        call :print_success "Cargo: %%i"
    )
)

:: Check Docker (optional)
call :command_exists "docker"
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('docker --version 2^>nul') do (
        call :print_success "Docker: %%i"
    )
)

:: Show key environment variables (without revealing sensitive values)
echo.
call :print_header "Key Environment Variables"

set "env_vars=ENVIRONMENT FRONTEND_PORT BACKEND_PORT DATABASE_URL SUPABASE_URL VITE_API_BASE_URL"

for %%v in (%env_vars%) do (
    call :get_env_var "%%v" env_value
    if not "!env_value!"=="" (
        :: Mask sensitive URLs and keys
        if "%%v"=="DATABASE_URL" (
            echo   %%v: [masked]
        ) else if "%%v"=="SUPABASE_URL" (
            echo   %%v: [masked]
        ) else (
            echo   %%v: !env_value!
        )
    ) else (
        echo   %%v: (not set)
    )
)

goto :eof

:export_environment
:: Export common development variables
if "%RUST_LOG%"=="" set "RUST_LOG=info"
if "%RUST_BACKTRACE%"=="" set "RUST_BACKTRACE=1"

:: Export paths
set "PROJECT_ROOT=%SCRIPT_DIR%"
set "CLIENT_DIR=%SCRIPT_DIR%src\client"
set "SERVER_DIR=%SCRIPT_DIR%src\server"

call :print_success "Environment exported for child processes"
goto :eof

:show_help
call :print_header "EMS Environment Loader (Windows)"
echo.
echo Usage: %~nx0 [command]
echo.
echo Commands:
echo   load      Load environment variables from config.env
echo   status    Show environment and tool status
echo   validate  Validate environment configuration
echo   help      Show this help message
echo.
echo Examples:
echo   %~nx0 status                    # Show environment status
echo   %~nx0 load                      # Load environment variables
echo   %~nx0 validate                  # Validate configuration
echo.
echo Note: On Windows, environment variables are automatically available
echo       to child processes started from the same command prompt.
goto :eof

:: Main execution
set "command=%~1"
if "%command%"=="" set "command=status"

if "%command%"=="load" (
    call :load_environment
    if errorlevel 1 (
        call :print_error "Failed to load environment"
        exit /b 1
    ) else (
        call :export_environment
        call :print_success "Environment loaded successfully!"
        call :print_warning "Environment variables are now available in this command prompt session"
    )
) else if "%command%"=="status" (
    call :load_environment
    if errorlevel 1 (
        call :print_error "Failed to load environment for status check"
        exit /b 1
    ) else (
        call :show_env_status
    )
) else if "%command%"=="validate" (
    call :load_environment
    if errorlevel 1 (
        call :print_error "Environment validation failed!"
        exit /b 1
    ) else (
        call :print_success "Environment validation passed!"
    )
) else if "%command%"=="help" (
    call :show_help
) else if "%command%"=="-h" (
    call :show_help
) else if "%command%"=="--help" (
    call :show_help
) else (
    call :print_error "Unknown command: %command%"
    call :print_warning "Run '%~nx0 help' for usage information"
    exit /b 1
) 