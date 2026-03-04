-- =============================================================================
-- HANA Express post-start initialization SQL
-- Executed once after the first successful start of the HANA instance.
-- Adjust the settings below to fit your development requirements.
-- =============================================================================

-- Allow HXE tenant to accept connections from any host (development only)
ALTER SYSTEM ALTER CONFIGURATION ('nameserver.ini', 'SYSTEM')
    SET ('public_hostname_resolution', 'use_default_route') = 'ip'
    WITH RECONFIGURE;

-- Reduce memory preloaded by column-store tables (dev optimization)
ALTER SYSTEM ALTER CONFIGURATION ('global.ini', 'SYSTEM')
    SET ('memorymanager', 'global_allocation_limit') = '8192'
    WITH RECONFIGURE;

-- Disable automatic merges to reduce background CPU in dev
ALTER SYSTEM ALTER CONFIGURATION ('global.ini', 'SYSTEM')
    SET ('mergedog', 'auto_merge_enabled') = 'no'
    WITH RECONFIGURE;
