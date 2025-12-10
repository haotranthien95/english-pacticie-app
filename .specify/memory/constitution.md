<!--
SYNC IMPACT REPORT - Constitution v1.0.0

Version Change: NONE (initial) → 1.0.0 (baseline)

Modified Principles:
- Created Principle I: Clean Architecture (Mandatory Layer Separation)
- Created Principle II: Test Coverage (Domain Logic ≥80%)
- Created Principle III: Functional Purity & Immutability
- Created Principle IV: Security & Secrets Management
- Created Principle V: AI-Assisted Development Governance
- Created Principle VI: Code Review & Human Oversight

Added Sections:
- Technology Constraints
- Development Workflow

Removed Sections: NONE

Templates Requiring Updates:
- ✅ .specify/templates/plan-template.md - Review for test coverage requirements
- ✅ .specify/templates/spec-template.md - Ensure security and architecture sections
- ✅ .specify/templates/tasks-template.md - Add test task requirements
- ✅ .specify/templates/commands/*.md - Verify AI restrictions referenced

Follow-up TODOs:
- NONE - All principles defined with concrete requirements

Rationale:
- MAJOR version (1.0.0) as this is the initial baseline establishing governance framework
- All principles derived from project requirements (English Learning App) and user specifications
- Focuses on Flutter (mobile) + FastAPI (backend) multi-component architecture
-->

# English Learning App Constitution

## Core Principles

### I. Clean Architecture (Mandatory Layer Separation)

**Non-Negotiable Rules**:
- MUST follow clean architecture pattern with strict layer boundaries
- Backend: Presentation (API routes) → Services (business logic) → Data (models/repositories)
- Mobile: Presentation (BLoC/UI) → Domain (use cases/entities) → Data (repositories/sources)
- Business logic MUST reside in service/domain layer ONLY - never in API routes or UI components
- Data models MUST be separated: Domain entities (pure), DTOs (serialization), Database models (ORM)
- Dependencies flow inward: Presentation → Domain ← Data (Dependency Inversion Principle)

**Rationale**: Enforces testability, maintainability, and prevents business logic leakage into presentation layer. Critical for mobile BLoC pattern and backend service-oriented design.

**Testing Validation**: Architecture compliance checked via layer dependency analysis - no direct data source imports in presentation layer.

---

### II. Test Coverage (Domain Logic ≥80%)

**Non-Negotiable Rules**:
- Domain/business logic MUST achieve ≥80% test coverage before PR approval
- Backend: All service classes, use cases, and business logic functions require unit tests
- Mobile: All BLoCs, use cases, and repositories require unit tests with mock data sources
- Integration tests REQUIRED for:
  - Backend: Authentication flow (JWT issuance, OAuth validation)
  - Backend: Speech-to-text API integration (Azure Speech SDK)
  - Mobile: Repository layer (API + local storage coordination)
  - Cross-component: API contract tests (request/response validation)
- Presentation layer (UI, routes): ≥60% coverage acceptable
- Test pyramid: 70% unit, 20% integration, 10% E2E

**Rationale**: Domain logic contains core business value - bugs here are most costly. Presentation code changes frequently (UI iterations) so lower threshold acceptable.

**Enforcement**: CI pipeline MUST block merges if domain coverage drops below 80%. Coverage reports generated per PR.

---

### III. Functional Purity & Immutability

**Non-Negotiable Rules**:
- Prefer pure functions (same input → same output, no side effects) for all business logic
- Backend: Service methods should be stateless where possible, avoid class-level mutable state
- Mobile: BLoC state objects MUST be immutable (use `@immutable` annotation, copyWith pattern)
- Mobile: Domain entities MUST be immutable value objects (use Equatable for comparison)
- Side effects (I/O, API calls, database writes) isolated to repository/data source layer
- Use functional error handling: Backend (Result/Either pattern optional), Mobile (dartz Either for Failure/Success)

**Exceptions Allowed**:
- Database connection pooling (inherently stateful)
- Audio streaming buffers (performance-critical, short-lived)
- BLoC event streams (reactive by design)

**Rationale**: Immutability prevents race conditions, simplifies reasoning about state changes, and makes testing deterministic. Critical for mobile BLoC pattern reliability.

**Testing Validation**: Unit tests verify functions produce consistent outputs, state objects cannot be mutated after creation.

---

### IV. Security & Secrets Management

**Non-Negotiable Rules**:
- ZERO secrets in source code - all credentials via environment variables or secret manager
- Backend: JWT secret, database URL, MinIO keys, Azure Speech API keys → `.env` file (gitignored) or cloud secret manager
- Mobile: Firebase config, API base URL → environment-specific build configs (never hardcoded)
- `.gitignore` MUST block: `.env`, `*.key`, `*.pem`, `google-services.json`, `firebase_options.dart` (use example templates)
- API keys in code trigger IMMEDIATE PR rejection and credential rotation
- Secrets rotation policy: Every 90 days for production, on-demand for suspected compromise

**Required Safeguards**:
- Pre-commit hooks scan for common secret patterns (API keys, tokens, passwords)
- CI pipeline secrets stored in GitHub Secrets / secure vault
- Production deployment uses managed secret services (AWS Secrets Manager, Azure Key Vault, etc.)

**Rationale**: Prevents credential leaks that compromise user data (PII in User table, OAuth tokens). One leaked API key can expose entire system.

**Enforcement**: Automated secret scanning in CI, manual code review checklist item.

---

### V. AI-Assisted Development Governance

**Non-Negotiable Rules**:
- AI tools (GitHub Copilot, ChatGPT, etc.) permitted for code generation, refactoring, documentation
- AI-generated code MUST be reviewed by human developer before commit (no auto-merge)
- AI MUST NEVER modify CI/CD pipeline files (`.github/workflows/*`, deployment scripts) without explicit human approval
- AI MUST NEVER modify security-critical files (auth services, encryption, secret management) without line-by-line human review
- AI-generated tests must achieve same coverage thresholds as human-written tests (Principle II applies)

**Human Review Requirements**:
- **Low Risk** (UI components, styling, documentation): Single reviewer approval sufficient
- **Medium Risk** (business logic, data models): Senior developer review required
- **High Risk** (authentication, payments, CI/CD, security): Two reviewer approval + security checklist

**Rationale**: AI accelerates development but lacks contextual security awareness and can introduce subtle bugs in critical paths. Human oversight ensures quality and safety.

**Enforcement**: PR templates include "AI-Generated Code" checkbox requiring explicit human review confirmation.

---

### VI. Code Review & Human Oversight

**Non-Negotiable Rules**:
- ALL code changes require human review before merge (no self-merges)
- Backend PRs: Minimum 1 reviewer (Python/FastAPI expertise)
- Mobile PRs: Minimum 1 reviewer (Flutter/Dart expertise)
- Cross-component PRs (API contract changes): Minimum 2 reviewers (1 backend + 1 mobile)
- Breaking changes (API schema, database migrations): Tech lead approval required
- Security-critical changes (auth, secrets, permissions): Security review + 2 approvals

**Review Checklist** (enforced via PR template):
1. ✅ Principle I: Layer separation maintained
2. ✅ Principle II: Test coverage ≥80% for domain logic
3. ✅ Principle III: Immutability and purity followed
4. ✅ Principle IV: No secrets in code
5. ✅ Principle V: AI-generated code reviewed
6. ✅ Documentation updated (API docs, README, inline comments)
7. ✅ Error handling implemented (no silent failures)

**Rationale**: Prevents regressions, knowledge sharing, catches bugs early. Two-reviewer requirement for cross-component changes ensures API contract alignment.

**Enforcement**: GitHub branch protection rules require approvals, CI checks must pass.

---

## Technology Constraints

### Approved Stack
- **Backend**: Python 3.12+, FastAPI, SQLAlchemy, PostgreSQL 12+, MinIO, Azure Speech SDK
- **Mobile**: Flutter 3.24.5+, Dart 3.5.4, BLoC pattern, Hive, Firebase Auth SDKs
- **Testing**: Backend (pytest, pytest-cov), Mobile (flutter_test, mockito, bloc_test)
- **CI/CD**: GitHub Actions (all workflow changes require Principle V human approval)

### Prohibited Practices
- Embedding business logic in API routes or UI widgets (violates Principle I)
- Mocking database in unit tests (use in-memory databases for integration tests instead)
- Global mutable state (violates Principle III)
- Storing secrets in source code (violates Principle IV)
- AI modifying CI/CD without approval (violates Principle V)

---

## Development Workflow

### Feature Development Process
1. **Specification**: Create/update spec in `spec/` directory with architectural decisions documented
2. **Plan**: Generate implementation plan in `specs/` with milestones and acceptance criteria
3. **Tasks**: Break down into granular tasks in `tasks.md` or `tasks-mobile.md` with test requirements
4. **Implementation**: Follow TDD for domain logic (Red → Green → Refactor)
5. **Review**: Submit PR with completed review checklist (Principle VI)
6. **Merge**: After approval + CI pass + coverage threshold met

### Quality Gates (CI Pipeline)
- ✅ All tests pass (unit + integration)
- ✅ Domain logic coverage ≥80% (Principle II)
- ✅ Linting passes (flake8 for Python, dart analyze for Flutter)
- ✅ No secrets detected (secret scanning tool)
- ✅ Code review approval (Principle VI)

### Amendment Process
- Constitution changes require PR to `.specify/memory/constitution.md`
- Must include: Rationale, affected principles, impact on existing code
- Requires 2 approvals from tech leads
- Version incremented per semantic versioning:
  - MAJOR: Principle removal or backward-incompatible governance change
  - MINOR: New principle added or existing principle materially expanded
  - PATCH: Clarifications, typo fixes, non-semantic refinements

---

## Governance

This constitution supersedes all other development practices and coding conventions. When conflicts arise between this document and team habits, **constitution rules prevail**.

### Compliance Verification
- All PRs MUST include review checklist confirming principle adherence
- CI pipeline enforces automated checks (coverage, secrets, linting)
- Quarterly constitution review to assess effectiveness and identify needed amendments

### Violation Handling
- **Minor violations** (styling, documentation gaps): Comment on PR, request fix before merge
- **Major violations** (insufficient tests, secrets in code, missing review): PR rejection, re-work required
- **Critical violations** (production secret leak, security vulnerability): Immediate incident response, post-mortem, credential rotation

### Guidance Documents
- For runtime agent/AI development instructions: See `.github/prompts/speckit.*.prompt.md` files
- For template structures: See `.specify/templates/*.md` files
- All guidance documents must align with this constitution

---

**Version**: 1.0.0 | **Ratified**: 2025-12-10 | **Last Amended**: 2025-12-10
