# Unit Tests Plan for Contably Workflows Module

## Objective

Write comprehensive unit tests for the workflows module to increase code coverage from current low levels (0-33%) to target of 80%+.

## Files to Test (17 files total)

### Core Workflow Engine (5 files)

1. `src/workflows/dsl_schema.py` - 0% coverage
   - Pydantic schemas for workflow DSL
   - Step types: Task, Parallel, Conditional, Loop, Approval, Delay, Notify
   - Join conditions: all, any, n_of_m, all_settled
   - Helper functions for parsing and validation

2. `src/workflows/executor.py` - 12% coverage
   - Main workflow execution engine
   - Sequential step execution
   - Context/variable management
   - Pause/resume/cancel operations
   - Error handling

3. `src/workflows/parallel_executor.py` - 0% coverage
   - Parallel task execution
   - Join condition handling
   - Error aggregation
   - Task cancellation

4. `src/workflows/scheduler.py` - 0% coverage
   - Cron-based job scheduling
   - Next run time calculation
   - Job execution and retry logic

5. `src/workflows/approval_service.py` - 12% coverage
   - Approval request creation
   - Approval/rejection handling
   - Delegation logic
   - Expiration and escalation

### SLA Service (1 file)

6. `src/workflows/sla_service.py` - 12% coverage
   - SLA deadline tracking
   - Violation detection
   - Warning notifications

### Monthly Closing (3 files)

7. `src/workflows/monthly_closing/workflow.py` - 13% coverage
8. `src/workflows/monthly_closing/closing.py` - 28% coverage
9. `src/workflows/monthly_closing/verification.py` - 33% coverage

### Payroll Orchestration Stages (6 files)

10. `src/workflows/payroll_orchestration/stages/ai_validation.py` - 13% coverage
11. `src/workflows/payroll_orchestration/stages/intake.py` - 18% coverage
12. `src/workflows/payroll_orchestration/stages/approval.py` - 33% coverage
13. `src/workflows/payroll_orchestration/stages/delivery.py` - 23% coverage
14. `src/workflows/payroll_orchestration/stages/dominio.py` - 24% coverage
15. `src/workflows/payroll_orchestration/stages/preview.py` - 26% coverage

### Payroll Validation (2 files group)

16-17. `src/workflows/payroll_validation/` - 0% coverage (all files)

- comparison.py
- esocial.py
- rules.py
- workflow.py

## Testing Strategy

### Test File Organization (7 new test files)

1. `test_dsl_schema.py` - DSL schema validation
2. `test_parallel_executor.py` - Parallel execution logic
3. `test_scheduler.py` - Scheduler logic
4. `test_approval_service.py` - Approval workflow
5. `test_wf_sla_service.py` - SLA tracking
6. `test_payroll_stages.py` - All payroll orchestration stages
7. `test_payroll_validators.py` - Payroll validation logic
8. `test_monthly_closing_suite.py` - Monthly closing workflows

(Note: Keep existing `test_workflow_executor.py`, `test_payroll_orchestration.py`, `test_payroll_validation.py`, `test_monthly_closing.py`)

### Test Coverage Goals by File

#### DSL Schema (dsl_schema.py)

- 15 test methods
- Test all enum types (StepType, JoinConditionType, ParallelErrorHandling)
- Test all Pydantic models with valid/invalid inputs
- Test validators (n_of_m, join_condition validation)
- Test helper functions (parse_workflow_config, create_parallel_group, validate_parallel_group)
- Edge cases: empty steps, max constraints, type coercion

#### Parallel Executor (parallel_executor.py)

- 15 test methods
- Mock async task execution
- Test join conditions: all, any, n_of_m, all_settled
- Test error handling: fail_fast, continue, partial_success
- Test timeout handling
- Test task cancellation on join
- Test output aggregation

#### Scheduler (scheduler.py)

- 15 test methods
- Test cron expression parsing
- Test next run time calculation with various timezones
- Test job execution retrieval
- Test job execution and retry logic
- Test job status updates
- Mock croniter and database calls

#### Approval Service (approval_service.py)

- 15 test methods
- Test approval request creation
- Test approval/rejection logic
- Test delegation
- Test expiration and escalation
- Test approval history tracking
- Mock database queries

#### SLA Service (sla_service.py)

- 12 test methods
- Test SLA deadline calculations
- Test warning threshold detection
- Test business hours logic
- Test violation notifications
- Mock time-based operations

#### Payroll Stages (6 stage files)

- Combined 18-20 test methods (3 per stage)
- Test intake: data validation, format conversion
- Test AI validation: LLM calls mocked
- Test approval: approval flow through stage
- Test preview: data preparation
- Test delivery: final submission
- Test dominio: specific dominio operations

#### Payroll Validators (payroll_validation/)

- 18 test methods
- Test comparison logic
- Test esocial validation rules
- Test custom rules validation
- Test workflow composition

#### Monthly Closing (3 files)

- 18 test methods combined
- Test closing workflow steps
- Test verification logic
- Test month transition handling

## Mock Strategy

All external dependencies must be mocked:

- AsyncSession (database)
- Celery tasks
- Redis cache
- LLM clients (Anthropic)
- External APIs
- File system operations
- Datetime operations (where needed)

Use `unittest.mock`:

- `AsyncMock` for async functions
- `MagicMock` for regular objects
- `patch` for module-level imports
- `PropertyMock` for property access

## Implementation Order

1. **Phase 1**: Core workflow engine tests (dsl_schema, executor, parallel_executor)
   - Foundation for other tests
   - No external dependencies

2. **Phase 2**: Utilities (scheduler, approval_service, sla_service)
   - Build on phase 1 patterns
   - More database mocking needed

3. **Phase 3**: Complex workflows (payroll stages, monthly closing)
   - Use patterns from earlier phases
   - More extensive service mocking

4. **Phase 4**: Validation logic (payroll_validation)
   - Domain-specific tests
   - Integration of other services

## Test Patterns & Best Practices

### Structure

- Use pytest classes to group related tests
- One test class per major feature/class
- Descriptive test names: `test_<feature>_<scenario>_<expectation>`

### Fixtures

- Reusable mock fixtures for database, models
- Parameterized tests for multiple scenarios
- Setup/teardown via fixtures

### Assertions

- Clear, specific assertions
- Test both happy path and error cases
- Validate side effects (e.g., database calls)

### Async Testing

- Use `pytest-asyncio` with `asyncio_mode = "auto"`
- All async functions use `async def`
- Use `await` for async calls

### Coverage Targets

- Each test file: minimum 12-15 test methods
- Happy path: 50% of tests
- Edge cases: 30% of tests
- Error conditions: 20% of tests

## Key Testing Scenarios

### For Each Module

**Happy Path**: Normal execution with valid inputs

- Expected outputs
- Side effects (database writes, logging)
- Status transitions

**Error Cases**: Invalid inputs and failure scenarios

- Type validation errors
- Missing required fields
- Database errors
- External service failures

**Edge Cases**: Boundary conditions

- Empty collections
- Maximum constraints
- Timeout scenarios
- Concurrent operations
- State transitions

## Files Already Existing (DO NOT DUPLICATE)

- `tests/unit/test_workflow_executor.py`
- `tests/unit/test_payroll_orchestration.py`
- `tests/unit/test_payroll_validation.py`
- `tests/unit/test_monthly_closing.py`
- `tests/unit/test_sla_service.py`

These should be checked for gaps and extended if needed, but not recreated.

## Execution Notes

- All tests run with `APP_ENV=test` and in-memory SQLite
- No actual Celery, Redis, or external services
- Mock configuration through conftest.py fixtures
- Tests should be fast (<5ms each on average)
- Can run full suite in <30 seconds

## Success Criteria

1. All 17 target files have test files
2. Minimum 80% code coverage per file
3. All tests pass with 100% success rate
4. No flaky tests (deterministic results)
5. Clear test names and documentation
6. Proper use of mocks throughout
7. No hardcoded test data in source files
