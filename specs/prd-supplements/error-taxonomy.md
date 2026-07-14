---
document_type: prd-supplement-error-taxonomy
level: L3
version: "1.0"
status: draft
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "a1dfc62558bfb6e93d2998cb24bd2b4cf4fe298faaecd92c1d69e118c6c8b172"
traces_to: prd.md
primary_consumers: [implementer, test-writer]
---

# Error Taxonomy: ferrochain

> PRD supplement — extracted from PRD Section 5.
> Source: CONFLICT-6 (adopt adk-rust P-01/P-04 2D component×category pattern).
> Codes follow convention: `E-<COMPONENT>-<NNN>` where COMPONENT is the crate abbreviation.
> All errors are `FerrochainError { component: Component, category: Category, retry_hint, code, message }`.

## Error Category Codes

| Category Code | Category | Description | RetryHint |
|--------------|----------|-------------|-----------|
| VAL | Validation | Input shape, type, range constraint violations | Never |
| AUTH | Authentication | Credentials absent, expired, or invalid | Maybe (refresh token) |
| RATE | Rate Limit | Provider or server rate limit exceeded | Later (backoff required) |
| TIMEOUT | Timeout | Outbound connection or response timeout | Later |
| TRANSPORT | Transport | TCP reset, TLS error, DNS failure | Later |
| INTERNAL | Internal | Assertion-like invariant violation; programming error | Never |
| DURABILITY | Durability | Checkpoint write or read failure | Maybe |
| POLICY | Policy | Policy constraint rejected the operation | Never (policy change required) |
| TOOL | Tool | Tool execution error (includes MCP ToolException) | Maybe |
| CONCURRENCY | Concurrency | Conflicting concurrent writes to same channel | Never |
| SECURITY | Security | Workspace escape, sandbox policy enforcement | Never |
| TENANCY | Tenancy | Session address collision, cross-tenant access attempt | Never |

## Severity Definitions

| Severity | Meaning | Surface Behavior |
|----------|---------|-----------------|
| broken | Cannot continue current operation; caller must handle | Non-zero exit / Err propagation |
| degraded | Partial result possible; caller may choose to surface partial data | Err with partial payload |
| cosmetic | Display or formatting issue only | Warning log; operation succeeds |

## Error Catalog

### Component: CORE (ferrochain-core)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-CORE-001 | VAL | broken | BC-2.01.001 | `Invalid ContentBlock type '<type>' in position <n> of message; expected one of: text, image_url, tool_use, tool_result, document` |
| E-CORE-002 | VAL | broken | BC-2.01.002 | `Message role '<role>' is not a recognized message type` |
| E-CORE-003 | VAL | broken | BC-2.01.003 | `Runnable input type mismatch: expected '<expected>', got '<actual>'` |
| E-CORE-004 | INTERNAL | broken | BC-2.01.004 | `Pipe composition failed: type boundary mismatch between stage <n> output and stage <n+1> input` |
| E-CORE-005 | VAL | broken | BC-2.14.006 | `Validation failed for '<field>': <reason>` |

### Component: GRAPH (ferrochain-graph)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-GRAPH-001 | CONCURRENCY | broken | BC-2.03.002 | `InvalidUpdateError: concurrent writes to LastValue channel '<channel>' from tasks [<task_ids>] in super-step <n>` |
| E-GRAPH-002 | POLICY | broken | BC-2.05.005 | `NoActiveInterrupt: no interrupt is pending for run '<run_id>'` |
| E-GRAPH-003 | VAL | broken | BC-2.02.001 | `Node '<node_id>' not found in graph definition` |
| E-GRAPH-004 | VAL | broken | BC-2.02.003 | `NamedBarrierValue channel '<channel>' received writes from unexpected keys: got [<keys>], expected [<expected_keys>]` |
| E-GRAPH-005 | POLICY | broken | BC-2.10.003 | `BudgetCeiling: run '<run_id>' halted; token budget of <limit> exceeded at <actual> tokens` |
| E-GRAPH-006 | INTERNAL | broken | BC-2.03.001 | `BspDeterminismViolation: reducer order constraint violated — contact maintainers with run_id '<run_id>'` |

### Component: CHKPT (ferrochain-checkpoint)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-CHKPT-001 | DURABILITY | broken | BC-2.04.001 | `CheckpointWriteFailed: put_writes for task '<task_id>' failed — backend error: <backend_error>` |
| E-CHKPT-002 | INTERNAL | broken | BC-2.04.003 | `MonotonicClockRegression: checkpoint ID <new_id> is not strictly greater than current <current_id>` |
| E-CHKPT-003 | DURABILITY | broken | BC-2.04.005 | `CheckpointReadFailed: cannot restore state for thread '<thread_id>' checkpoint '<checkpoint_id>': <reason>` |
| E-CHKPT-004 | SECURITY | broken | BC-2.04.007 | `EncryptionKeyRotationFailed: checkpoint state encryption key rotation error: <reason>` |
| E-CHKPT-005 | TENANCY | broken | BC-2.04.006 | `SessionAddressCollision: operation with (thread_id='<t>', ns='<ns>') conflicts with existing session — triple must be unique` |

### Component: SERVER (ferrochain-server)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-SERVER-001 | POLICY | broken | BC-2.13.003 | `PolicyNotEnforceable: strict sandbox policy requires enforcing backend; process backend is not permitted` |
| E-SERVER-002 | VAL | broken | BC-2.12.003 | `RunNotFound: run '<run_id>' does not exist in thread '<thread_id>'` |
| E-SERVER-003 | VAL | broken | BC-2.12.001 | `ThreadNotFound: thread '<thread_id>' does not exist` |
| E-SERVER-004 | AUTH | broken | BC-2.12.005 | `DebugRouteUnauthorized: debug/introspection route requires explicit opt-in configuration` |
| E-SERVER-005 | POLICY | broken | BC-2.12.005 | `CorsRejected: CORS origin '<origin>' is not in the allow-list; default denies all cross-origin requests` |

### Component: PROV (ferrochain-\<provider\>)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-PROV-001 | RATE | degraded | BC-2.08.004 | `RateLimited: provider '<provider>' returned 429; retry after <retry_after>s` |
| E-PROV-002 | TIMEOUT | broken | BC-2.08.007 | `ProviderTimeout: streaming connection to '<provider>' timed out after <ms>ms` |
| E-PROV-003 | TRANSPORT | broken | BC-2.08.007 | `StreamInterrupted: TCP connection to '<provider>' reset mid-stream after <tokens> tokens` |
| E-PROV-004 | AUTH | broken | BC-2.08.004 | `ProviderAuthFailed: '<provider>' rejected API key — check credentials` |
| E-PROV-005 | VAL | broken | BC-2.08.003 | `StructuredOutputParseError: provider response did not match expected JSON schema: <path> — <reason>` |

### Component: MCP (ferrochain-mcp)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-MCP-001 | TOOL | broken | BC-2.09.004 | `ToolException: MCP server '<server>' raised ToolException for tool '<tool>': <message>` |
| E-MCP-002 | TRANSPORT | broken | BC-2.09.001 | `McpTransportError: cannot connect to MCP server '<server>': <transport_error>` |
| E-MCP-003 | VAL | broken | BC-2.09.005 | `McpNotImplemented: MCP server '<server>' does not implement '<method>'` |
| E-MCP-004 | VAL | broken | BC-2.09.002 | `ToolNotFound: tool '<tool_name>' is not registered with any MCP server` |

### Component: SPLIT (ferrochain-splitters)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-SPLIT-001 | VAL | broken | BC-2.07.001 | `ZeroChunkSize: chunk_size must be > 0 code points; got 0` |
| E-SPLIT-002 | VAL | broken | BC-2.07.001 | `OverlapExceedsChunk: overlap <overlap> must be < chunk_size <chunk_size>` |

### Component: SBXD (ferrochain-sandbox)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-SBXD-001 | SECURITY | broken | BC-2.13.005 | `WorkspaceEscape: resolved path '<resolved>' escapes workspace root '<root>'` |
| E-SBXD-002 | POLICY | broken | BC-2.13.003 | `PolicyNotEnforceable: execution policy requires enforcing sandbox; non-enforcing backend is configured` |
| E-SBXD-003 | INTERNAL | broken | BC-2.13.001 | `SandboxInitFailed: cannot initialize WASM/container sandbox backend: <reason>` |

## RFC-7807 Problem Emission

All `FerrochainError` values must be emittable as RFC-7807 problem+json when surfaced
via HTTP (ferrochain-server). The mapping is:

| FerrochainError field | RFC-7807 field |
|-----------------------|---------------|
| code (e.g., E-GRAPH-001) | `type` (URI: `urn:ferrochain:error:<code>`) |
| message | `detail` |
| category | `title` (humanized category name) |
| component | embedded in `type` URI |
| retry_hint | `extensions.retry_hint` (never/maybe/later) |

## RetryHint Values

| Value | Meaning | Client Behavior |
|-------|---------|----------------|
| `Never` | Retrying will not help; caller must fix input or config | Do not retry |
| `Maybe` | Retry once with same input; transient errors only | Retry once, then give up |
| `Later(Duration)` | Rate limit or temporary unavailability; wait and retry | Respect backoff |
