# Unit Tests Writing Plan - Contably API

## Objective

Write comprehensive unit tests for RPA, deadlines, accounting, API deps, and model files to increase code coverage.

## Files to Test

### RPA Module (33-49% coverage)

1. `src/rpa/credentials.py` - SecureCredential, EncryptionHelper, CredentialManager (33%)
2. `src/rpa/engine.py` - RPAEngine, RPAWorker, execution context (40%)
3. `src/rpa/logging_capture.py` - Logging capture mechanism (41%)
4. `src/rpa/recovery.py` - Recovery/retry logic (38%)
5. `src/rpa/script.py` - Script execution/validation (49%)

### API Deps Module

1. `src/api/deps/auth.py` - Auth functions, token management
2. `src/api/deps/company_access.py` - Company access checks
3. `src/api/deps/database.py` - DB session management
4. `src/api/deps/pagination.py` - Pagination logic
5. `src/api/deps/permissions.py` - Permission checks
6. `src/api/deps/rate_limiting.py` - Rate limiting
7. `src/api/errors.py` - Error handling
8. `src/api/middleware/metrics.py` - Metrics collection

### Other Modules

1. `src/deadlines/service.py` - Deadline logic
2. `src/accounting/journal_generator.py` - Journal generation

### Models (Instantiation Tests)

1. `src/models/api_keys.py`
2. `src/models/audit.py`
3. `src/models/client_portal.py`
4. `src/models/erp_sync.py`
5. `src/models/orchestrator.py`
6. `src/models/orchestrator_jobs.py`
7. `src/models/portal.py`
8. `src/models/service_accounts.py`
9. `src/models/system_settings.py`
10. `src/models/scheduled_jobs.py`
11. `src/models/workflows.py`

## Test Files to Create (NEW)

1. `tests/unit/test_rpa_credentials_coverage.py` - Credential encryption/decryption, storage, rotation
2. `tests/unit/test_rpa_engine_coverage.py` - RPAEngine execution flow, error handling
3. `tests/unit/test_rpa_logging_capture.py` - Log capture mechanisms
4. `tests/unit/test_rpa_recovery.py` - Recovery/retry strategies
5. `tests/unit/test_rpa_script.py` - Script execution, validation
6. `tests/unit/test_api_deps_auth_coverage.py` - Token creation, validation, password hashing
7. `tests/unit/test_api_deps_company_access.py` - Company access logic
8. `tests/unit/test_api_deps_database.py` - DB session management
9. `tests/unit/test_api_deps_pagination.py` - Pagination edge cases
10. `tests/unit/test_api_deps_permissions.py` - Permission checks
11. `tests/unit/test_api_deps_rate_limiting.py` - Rate limiting
12. `tests/unit/test_api_errors.py` - Error classes
13. `tests/unit/test_api_metrics.py` - Metrics middleware
14. `tests/unit/test_deadlines_service.py` - Deadline logic
15. `tests/unit/test_journal_generator.py` - Journal generation
16. `tests/unit/test_models_extended.py` - Model instantiation

## Test Strategy

### For RPA Module:

- Mock external dependencies (Playwright, file system, encryption)
- Test encryption/decryption with real Fernet (no mock)
- Test credential storage, retrieval, deletion
- Test execution context creation and parameter handling
- Test error handling and recovery mechanisms
- Test logging capture

### For API Deps:

- Mock database sessions
- Mock Redis for rate limiting
- Test token generation, validation
- Test permission checks
- Test pagination edge cases (page 0, negative, max)
- Test authentication errors

### For Models:

- Instantiate models with valid data
- Test field validation
- Test relationship initialization
- Test to_dict/to_orm_dict methods if present
- Test required vs optional fields

## Test File Pattern

```python
"""
Test description

Tests for src.module.submodule
Covers: functionality description
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from sqlalchemy.ext.asyncio import AsyncSession

# Import subject under test
from src.module.submodule import SomeClass

# Setup fixtures specific to this file

# Tests grouped by functionality
class TestClassName:
    @pytest.mark.asyncio
    async def test_async_method(self):
        ...

    def test_sync_method(self):
        ...
```

## Verification Checklist

- [ ] All RPA modules have 80%+ coverage
- [ ] All API deps have >80% coverage
- [ ] All test files use AsyncMock/MagicMock for external services
- [ ] No comments like "# Add more tests"
- [ ] Each test file has 10-15 test methods
- [ ] Tests use pytest fixtures from conftest.py
- [ ] Edge cases tested (empty, None, errors)
- [ ] Async/await patterns tested correctly
- [ ] Mock file I/O and network calls
- [ ] Test names are descriptive

## Notes

- Use existing test patterns from test_rpa_engine.py, test_auth.py
- Leverage conftest.py fixtures (db_session, mock_redis, etc.)
- Mock at module boundaries, not internal functions
- Test both success and failure paths
- Use parametrize for multiple test cases
