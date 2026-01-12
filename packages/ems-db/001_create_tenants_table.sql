-- Migration: Create tenants table
-- This migration creates the multi-tenancy infrastructure
-- PREREQUISITE: Run 000_supabase_setup.sql first

-- Create tenants table
CREATE TABLE public.tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  subdomain VARCHAR(50) UNIQUE NOT NULL,
  database_url VARCHAR(500),
  settings JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for tenants table
CREATE INDEX idx_tenants_subdomain ON public.tenants(subdomain);
CREATE INDEX idx_tenants_is_active ON public.tenants(is_active);
CREATE INDEX idx_tenants_name ON public.tenants(name);

-- Create trigger for updated_at timestamp (uses function from 000_supabase_setup.sql)
CREATE TRIGGER update_tenants_updated_at 
    BEFORE UPDATE ON public.tenants 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Add RLS (Row Level Security) policies for tenant isolation
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for tenants - users can only see their own tenant
CREATE POLICY "tenant_isolation" ON public.tenants
    FOR ALL USING (
        id = public.get_current_tenant_id()
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tenants TO authenticated, service_role;

-- Insert a default tenant for development/testing
INSERT INTO public.tenants (name, subdomain, is_active) 
VALUES ('Default Tenant', 'default', true); 