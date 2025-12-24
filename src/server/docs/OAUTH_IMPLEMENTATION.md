# OAuth Authentication Implementation

This document describes the OAuth authentication implementation for the EMS Server with support for Google, Microsoft, and Apple authentication for internal persons with proper tenant isolation.

## Overview

The OAuth implementation provides secure authentication for internal persons using social login providers while maintaining strict tenant isolation. Each internal person belongs to a specific tenant and can only access resources within that tenant.

## Supported Providers

- **Google OAuth 2.0**: Complete implementation with user info extraction
- **Microsoft OAuth 2.0**: Complete implementation with Microsoft Graph API integration
- **Apple Sign In**: Partial implementation (ID token decoding needs completion)

## Environment Variables

Add the following environment variables to your `.env` file:

```bash
# Supabase Configuration (Required)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# JWT Configuration (Required)
JWT_SECRET=your-jwt-secret-key-here

# Google OAuth Configuration (Optional)
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/oauth/callback

# Microsoft OAuth Configuration (Optional)
MICROSOFT_CLIENT_ID=your-microsoft-client-id
MICROSOFT_CLIENT_SECRET=your-microsoft-client-secret
MICROSOFT_REDIRECT_URL=http://localhost:3000/auth/oauth/callback
MICROSOFT_TENANT_ID=common  # or your specific tenant ID

# Apple OAuth Configuration (Optional)
APPLE_CLIENT_ID=your.apple.client.id
APPLE_CLIENT_SECRET=your-apple-client-secret
APPLE_REDIRECT_URL=http://localhost:3000/auth/oauth/callback
```

## API Endpoints

### 1. Get OAuth Authorization URL

**POST** `/api/v1/auth/oauth/url`

Generate an OAuth authorization URL for the specified provider and tenant.

**Request Body:**
```json
{
  "provider": "google",  // "google", "microsoft", or "apple"
  "tenant_subdomain": "acme-corp",
  "redirect_url": "http://localhost:3000/auth/callback"  // Optional
}
```

**Response:**
```json
{
  "auth_url": "https://accounts.google.com/o/oauth2/v2/auth?client_id=...",
  "state": "acme-corp:uuid-here"
}
```

**Usage Example:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/oauth/url \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "google",
    "tenant_subdomain": "acme-corp"
  }'
```

### 2. OAuth Callback (Login)

**POST** `/api/v1/auth/oauth/callback`

Handle OAuth callback and authenticate an existing internal person.

**Request Body:**
```json
{
  "provider": "google",
  "code": "4/0AdQt8qhXXXXXXXXX",
  "state": "acme-corp:uuid-here",
  "tenant_subdomain": "acme-corp"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-here",
    "email": "john.doe@acme-corp.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "internal"
  },
  "tenant": {
    "id": "uuid-here",
    "name": "Acme Corp",
    "subdomain": "acme-corp"
  }
}
```

### 3. OAuth Registration (Internal Person)

**POST** `/api/v1/auth/oauth/register/internal`

Register a new internal person and create a new tenant using OAuth.

**Request Body:**
```json
{
  "provider": "google",
  "code": "4/0AdQt8qhXXXXXXXXX",
  "state": "new-tenant:uuid-here",
  "tenant_subdomain": "new-tenant",
  "tenant_name": "New Company",
  "department": "Engineering",      // Optional
  "position": "Software Engineer",  // Optional
  "employee_id": "EMP001"          // Optional
}
```

**Response:** Same as OAuth callback response.

## OAuth Flow Examples

### Google OAuth Flow

1. **Frontend initiates OAuth:**
```javascript
// Get OAuth URL
const response = await fetch('/api/v1/auth/oauth/url', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    provider: 'google',
    tenant_subdomain: 'acme-corp'
  })
});

const { auth_url, state } = await response.json();

// Redirect user to OAuth provider
window.location.href = auth_url;
```

2. **Handle OAuth callback:**
```javascript
// After OAuth redirect, extract code from URL
const urlParams = new URLSearchParams(window.location.search);
const code = urlParams.get('code');
const state = urlParams.get('state');

// Complete authentication
const response = await fetch('/api/v1/auth/oauth/callback', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    provider: 'google',
    code: code,
    state: state,
    tenant_subdomain: 'acme-corp'
  })
});

const { access_token, refresh_token, user, tenant } = await response.json();

// Store tokens and user info
localStorage.setItem('access_token', access_token);
localStorage.setItem('refresh_token', refresh_token);
```

### Microsoft OAuth Flow

Same as Google, but use `provider: "microsoft"` in requests.

### Apple OAuth Flow

Same as Google, but use `provider: "apple"` in requests.

**Note:** Apple OAuth implementation requires additional ID token decoding logic which is currently not fully implemented.

## Security Features

### Tenant Isolation

- Each OAuth flow must specify a `tenant_subdomain`
- State parameter includes tenant information for validation
- Users can only authenticate for tenants they belong to
- JWT tokens include tenant context

### State Parameter Validation

- State parameter format: `{tenant_subdomain}:{uuid}`
- Prevents CSRF attacks
- Validates tenant context throughout the flow

### JWT Token Security

- Access tokens expire after 1 hour
- Refresh tokens expire after 30 days
- Tokens include tenant and user context
- Token blacklisting support for logout

## Error Handling

### Common Error Responses

**Tenant Not Found (404):**
```json
{
  "error": "Tenant not found"
}
```

**Tenant Inactive (403):**
```json
{
  "error": "Tenant is not active"
}
```

**OAuth Provider Not Configured (503):**
```json
{
  "error": "Google OAuth is not configured"
}
```

**Invalid State Parameter (400):**
```json
{
  "error": "Invalid state parameter"
}
```

**User Not Found (404):**
```json
{
  "error": "User not found. Please register first or contact your administrator to add you to this tenant."
}
```

**User Not Internal (403):**
```json
{
  "error": "User is not an internal person for this tenant"
}
```

## Database Schema

### Person Table
```sql
CREATE TABLE person (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supabase_uid UUID NOT NULL,  -- OAuth users get a generated UUID
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    global_access TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Internal Person Table
```sql
CREATE TABLE internal_person (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES person(id),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    department VARCHAR(50),
    position VARCHAR(100),
    employee_id VARCHAR(20),
    hire_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## OAuth Provider Setup

### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
5. Set application type to "Web application"
6. Add authorized redirect URIs: `http://localhost:3000/auth/oauth/callback`
7. Copy Client ID and Client Secret to environment variables

### Microsoft OAuth Setup

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to "Azure Active Directory" → "App registrations"
3. Click "New registration"
4. Set redirect URI: `http://localhost:3000/auth/oauth/callback`
5. Go to "Certificates & secrets" and create a new client secret
6. Copy Application (client) ID and client secret to environment variables

### Apple Sign In Setup

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Create a new identifier for "Sign in with Apple"
4. Configure domain and return URLs
5. Create a Service ID and configure it
6. Generate a private key and create a client secret JWT
7. Set environment variables with Service ID and generated secret

## Testing

### Manual Testing with cURL

1. **Get OAuth URL:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/oauth/url \
  -H "Content-Type: application/json" \
  -d '{"provider": "google", "tenant_subdomain": "test-tenant"}'
```

2. **Visit the returned auth_url in a browser**

3. **Complete OAuth callback:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/oauth/callback \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "google",
    "code": "OAUTH_CODE_FROM_CALLBACK",
    "state": "test-tenant:uuid",
    "tenant_subdomain": "test-tenant"
  }'
```

### Integration Testing

The implementation supports standard OAuth 2.0 flows and can be tested with OAuth testing tools like Postman or OAuth 2.0 Playground.

## Limitations and Future Improvements

### Current Limitations

1. **Apple OAuth**: ID token decoding is not fully implemented
2. **PKCE**: Not implemented (recommended for mobile apps)
3. **Refresh Token Rotation**: Not implemented
4. **Rate Limiting**: Not implemented for OAuth endpoints

### Future Improvements

1. Complete Apple OAuth ID token decoding
2. Add PKCE support for enhanced security
3. Implement refresh token rotation
4. Add OAuth-specific rate limiting
5. Add OAuth audit logging
6. Support for additional providers (GitHub, LinkedIn, etc.)

## Troubleshooting

### Common Issues

1. **"OAuth provider not configured"**: Check environment variables
2. **"Invalid redirect URI"**: Ensure redirect URIs match OAuth provider configuration
3. **"Invalid state parameter"**: Check state parameter format and tenant validation
4. **"User not found"**: User must be created in the system before OAuth login

### Debug Logging

Enable debug logging by setting the `RUST_LOG` environment variable:
```bash
RUST_LOG=debug cargo run
```

This will show detailed OAuth flow information including request/response data.

## Security Considerations

1. **Always use HTTPS in production**
2. **Validate all OAuth provider certificates**
3. **Implement proper CORS policies**
4. **Use secure storage for client secrets**
5. **Regularly rotate OAuth client secrets**
6. **Monitor OAuth flow failures for potential attacks**
7. **Implement rate limiting to prevent abuse**

---

For additional support or questions, please refer to the main project documentation or create an issue in the project repository. 