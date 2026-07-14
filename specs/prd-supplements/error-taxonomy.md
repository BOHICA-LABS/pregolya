---
document_type: prd-supplement-error-taxonomy
level: L3
version: "1.1"
status: active
producer: product-owner
timestamp: 2026-07-14T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-25): F-P25-02 recategorize E-SERVER-004 AUTH→POLICY; correction note added inline."
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
| E-CORE-001 | VAL | broken | BC-2.01.001 | `StrictContentBlockValidation: block at position <n> has unrecognized type tag '<type>'; not in KNOWN_BLOCK_TYPES — use lenient deserialization for NonStandard passthrough` |
| E-CORE-002 | VAL | broken | BC-2.01.002 | `Message role '<role>' is not a recognized message type` |
| E-CORE-003 | VAL | broken | BC-2.01.003 | `Runnable input type mismatch: expected '<expected>', got '<actual>'` |
| E-CORE-004 | INTERNAL | broken | BC-2.01.004 | `Pipe composition failed: type boundary mismatch between stage <n> output and stage <n+1> input` |
| E-CORE-005 | VAL | broken | BC-2.14.006 | `Validation failed for '<field>': <reason>` |

### Component: GRAPH (ferrochain-graph)

> **GRAPH reconciliation note (ADV-P1D-FIX-1 burst, 2026-07-14):** BC authors (ss-02/ss-05)
> independently assigned E-GRAPH-NNN codes without consulting this taxonomy, producing 6+
> collisions where the same code had different meanings in BCs vs taxonomy. Resolution:
> E-GRAPH-001..006 taxonomy meanings are kept stable (source of truth). All colliding BC
> usages are renumbered to E-GRAPH-007..014 below. E-GRAPH-003 renamed from "Node not
> found" to "UnknownRoutingTarget" (functionally identical; anchor corrected to BC-2.02.005
> which is the primary routing BC). E-GRAPH-004 renamed from "NamedBarrierValue unexpected
> keys" to "DuplicateBarrierWrite" (BC-2.02.003 EC-003 updated to use this code).
> Process-gap follow-up: Phase 2 backlog story for a global cross-component collision lint.

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-GRAPH-001 | CONCURRENCY | broken | BC-2.03.002 | `InvalidUpdateError: concurrent writes to LastValue channel '<channel>' from tasks [<task_ids>] in super-step <n>` |
| E-GRAPH-002 | POLICY | broken | BC-2.05.005 | `NoActiveInterrupt: no interrupt is pending for run '<run_id>'` |
| E-GRAPH-003 | VAL | broken | BC-2.02.005 | `UnknownRoutingTarget: node '<node_id>' is not registered in the compiled graph` |
| E-GRAPH-004 | VAL | broken | BC-2.02.003 | `DuplicateBarrierWrite: NamedBarrierValue channel '<channel>' received more than one write from writer '<writer>' in super-step <n>` |
| ~~E-GRAPH-005~~ | ~~POLICY~~ | ~~broken~~ | ~~BC-2.10.003~~ | ~~`BudgetCeiling: ...`~~ — **RETIRED** (ADV-P1D-PASS-2 fix, 2026-07-14): budget errors belong in the BUDGET component namespace. E-GRAPH-005 is superseded by E-BUDGET-001. Code never shipped; tombstone per append-only numbering policy. |
| E-GRAPH-006 | INTERNAL | broken | BC-2.03.001 | `BspDeterminismViolation: reducer order constraint violated — contact maintainers with run_id '<run_id>'` |
| E-GRAPH-007 | VAL | broken | BC-2.02.001 | `UnknownChannelKey: node '<node_id>' returned write for key '<key>' which is not registered in the state schema` |
| E-GRAPH-008 | VAL | broken | BC-2.02.001 | `UnreachableGraph: <reason> (e.g., "no entry edge from START")` |
| E-GRAPH-009 | VAL | broken | BC-2.02.001 | `DuplicateNodeName: node '<name>' is already registered in this graph` |
| E-GRAPH-010 | VAL | broken | BC-2.02.003 | `UnknownBarrierWriter: NamedBarrierValue channel '<channel>' declares writer '<writer>' which is not a registered node` |
| E-GRAPH-011 | INTERNAL | broken | BC-2.02.005 | `ConditionalEdgePanic: routing function for edge from '<source_node>' panicked: <message>` |
| E-GRAPH-012 | VAL | broken | BC-2.02.005 | `UnmappedRouteKey: path_fn returned symbolic key '<key>' not found in path_map` |
| E-GRAPH-013 | SECURITY | broken | BC-2.05.006 | `InsufficientApproverRole: action requires role '<required>'; caller presented role '<provided>'` |
| E-GRAPH-014 | POLICY | broken | BC-2.05.006 | `InterruptApprovalTimeout: interrupt for run '<run_id>' (tier '<tier>') expired at deadline '<deadline_utc>' without receiving required approval` |
| E-GRAPH-015 | VAL | broken | BC-2.05.004 | `NoParentGraph: Command.PARENT is only valid inside a subgraph execution context; no parent graph is active` |
| E-GRAPH-016 | POLICY | broken | BC-2.05.001 (secondary: BC-2.10.004) | `InterruptWithoutCheckpointer: interrupt() requires a CheckpointSaver attached to the graph; no durable state is available to park the interrupted run` |

### Component: CHKPT (ferrochain-checkpoint)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-CHKPT-001 | DURABILITY | broken | BC-2.04.001 | `CheckpointWriteFailed: put_writes for task '<task_id>' failed — backend error: <backend_error>` |
| E-CHKPT-002 | INTERNAL | broken | BC-2.04.003 | `MonotonicClockRegression: checkpoint ID <new_id> is not strictly greater than current <current_id>` |
| E-CHKPT-003 | DURABILITY | broken | BC-2.04.005 | `CheckpointReadFailed: cannot restore state for thread '<thread_id>' checkpoint '<checkpoint_id>': <reason>` |
| E-CHKPT-004 | SECURITY | broken | BC-2.04.007 | `EncryptionKeyRotationFailed: checkpoint state encryption key rotation error: <reason>` |
| E-CHKPT-005 | TENANCY | broken | BC-2.04.006 | `SessionAddressCollision: operation with (thread_id='<t>', ns='<ns>') conflicts with existing session — triple must be unique` |
| E-CHKPT-006 | INTERNAL | broken | BC-2.05.001 | `SerializationFailed: interrupt_value cannot be serialized by the configured checkpoint serializer — type contract violation (programming error)` |

### Component: SERVER (ferrochain-server)

> **Collision resolution note (sub-burst reconciliation 2026-07-13):** Batch 10 BCs
> authored codes 007–012 (Thread/Assistant/Run lifecycle errors). Batch 11 BCs independently
> numbered from 006. Resolution: Batch 10 codes 007–012 are authoritative; Batch 11 codes
> that collided (was 007/008/009) are renumbered to 013/014/015. Code 006 (ScheduleNotFound)
> had no collision and is preserved as-is.

| Error Code | Category | Severity | BC Anchor | RetryHint | Message Format |
|-----------|----------|----------|-----------|-----------|---------------|
| ~~E-SERVER-001~~ | ~~POLICY~~ | ~~broken~~ | ~~BC-2.13.003~~ | ~~Never~~ | ~~`PolicyNotEnforceable: ...`~~ — **RETIRED** (ADV-P1D-PASS-4 fix, 2026-07-14): duplicate of E-SBXD-002; mis-anchored to SERVER component when the error is emitted by ferrochain-sandbox. BC-2.13.003 emits E-SBXD-002; E-SERVER-001 was never used. Tombstone per append-only numbering policy. |
| E-SERVER-002 | VAL | broken | BC-2.12.003 | Never | `RunNotFound: run '<run_id>' does not exist in thread '<thread_id>'` |
| E-SERVER-003 | VAL | broken | BC-2.12.001 | Never | `ThreadNotFound: thread '<thread_id>' does not exist` |
| E-SERVER-004 | POLICY | broken | BC-2.12.005 | Never | `DebugRouteUnauthorized: debug/introspection route requires explicit opt-in configuration` — **Category correction (F-P25-02, ADV-P1D-PASS-25):** was AUTH → POLICY. See note below table. |
| E-SERVER-005 | POLICY | broken | BC-2.12.005 | Never | `CorsRejected: CORS origin '<origin>' is not in the allow-list; default denies all cross-origin requests` |
| E-SERVER-006 | VAL | broken | BC-2.12.004 | Never | `ScheduleNotFound: cron schedule '<cron_id>' does not exist` |
| E-SERVER-007 | CONCURRENCY | broken | BC-2.12.001 | Never | `ThreadAlreadyExists: thread '<thread_id>' already exists` |
| E-SERVER-008 | POLICY | broken | BC-2.12.001 | Never | `ThreadStateConflict: thread '<thread_id>' has an active run '<run_id>'; state updates during active runs are disallowed` |
| E-SERVER-009 | VAL | broken | BC-2.12.002 | Never | `AssistantNotFound: assistant '<assistant_id>' does not exist` |
| E-SERVER-010 | VAL | broken | BC-2.12.002 | Never | `AssistantVersionNotFound: assistant '<assistant_id>' has no version <version>` |
| E-SERVER-011 | VAL | broken | BC-2.12.002 | Never | `GraphNotFound: graph '<graph_id>' is not registered with this server instance` |
| E-SERVER-012 | CONCURRENCY | broken | BC-2.12.003 | Never | `ConcurrentRun: thread '<thread_id>' already has an active run; use multitask_strategy to override` |
| E-SERVER-013 | VAL | broken | BC-2.12.005 | Never | `InvalidDebugRouteKey: debug_route_key must be non-empty` |
| E-SERVER-014 | DURABILITY | broken | BC-2.12.006 | Maybe | `RunStoreFailed: RunStore write failed for run '<run_id>' during transition '<transition>': <backend_error>` |
| E-SERVER-015 | CONCURRENCY | broken | BC-2.12.007 | Never | `RunAlreadyExecuting: run '<run_id>' is already being executed; concurrent execution rejected` |
| E-SERVER-016 | TIMEOUT | broken | BC-2.12.006 | Later | `IdempotencyLockTimeout: in-flight deduplication lock for key '<key>' held for ><timeout>s; lock_timeout is configurable via IdempotencyStore` |

> **E-SERVER-004 category correction (F-P25-02, ADV-P1D-PASS-25):** E-SERVER-004 was incorrectly
> categorized as AUTH (Category::Auth → HTTP 401). BC-2.12.005 PC4 + EC-002 mandate HTTP 403 and
> describe this as a policy gate (route inaccessible without explicit operator opt-in config), not a
> credential-based authentication failure. Recategorized AUTH → POLICY (Category::Policy → HTTP 403).
> The debug route is a capability gate, not an identity gate. The 401 row in interface-definitions.md
> §HTTP Status Codes is now marked reserved (no E-code maps there in v1).

### Component: PROV (ferrochain-\<provider\>)

| Error Code | Category | Severity | BC Anchor | Message Format |
|-----------|----------|----------|-----------|---------------|
| E-PROV-001 | RATE | degraded | BC-2.08.004 | `RateLimited: provider '<provider>' returned 429; retry after <retry_after>s` |
| E-PROV-002 | TIMEOUT | broken | BC-2.08.007 | `ProviderTimeout: streaming connection to '<provider>' timed out after <ms>ms` |
| E-PROV-003 | TRANSPORT | broken | BC-2.08.007 | `StreamInterrupted: TCP connection to '<provider>' reset mid-stream after <tokens> tokens` |
| E-PROV-004 | AUTH | broken | BC-2.08.004 | `ProviderAuthFailed: '<provider>' rejected API key — check credentials` |
| E-PROV-005 | VAL | broken | BC-2.08.003 | `StructuredOutputParseError: provider response did not match expected JSON schema: <path> — <reason>` |
| E-PROV-006 | VAL | broken | BC-2.08.004 | `ContextLengthExceeded: provider '<provider>' rejected request — context length <actual> exceeds maximum <limit> tokens` |

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
| E-SBXD-001 | SECURITY | broken | BC-2.13.005 (also BC-2.13.004/VP-003 — shared canonicalize_beneath_root code path; VP-003 verifies the guard, BC-2.13.005 specifies the error surface) | `WorkspaceEscape: resolved path '<resolved>' escapes workspace root '<root>'` |
| E-SBXD-002 | POLICY | broken | BC-2.13.003 | `PolicyNotEnforceable: execution policy requires enforcing sandbox; non-enforcing backend is configured` |
| E-SBXD-003 | INTERNAL | broken | BC-2.13.001 | `SandboxInitFailed: cannot initialize WASM/container sandbox backend: <reason>` |
| E-SBXD-004 | POLICY | broken | BC-2.13.006 | `PlatformNoEnforcement: macOS Seatbelt allow-list cannot be enumerated for this tool — <reason>; use SandboxPolicy::allow_no_sandbox() to opt in to unsandboxed execution` |
| E-SBXD-005 | INTERNAL | broken | BC-2.13.006 | `BackendUnavailable: Seatbelt sandbox API is not supported on this macOS version — <reason>; does not silently fall back to process execution` |

### Component: RETRY (ferrochain-core retry combinator)

| Error Code | Category | Severity | BC Anchor | RetryHint | Message Format |
|-----------|----------|----------|-----------|-----------|---------------|
| E-RETRY-001 | POLICY | broken | BC-2.16.001 | Never | `RetryExhausted: per-tool retry limit for tool '<tool_name>' exhausted after <attempt_limit> attempts` |
| E-RETRY-002 | POLICY | broken | BC-2.16.002 | Never | `GlobalLimitExhausted: global retry budget of <global_limit> exhausted across all tools in this run` |
| E-RETRY-003 | POLICY | broken | BC-2.16.003 | `Later(<reset_timeout>)` | `CircuitBreakerOpen: tool '<tool_name>' circuit tripped after <failure_threshold> consecutive failures` |

### Component: CRON (ferrochain-server scheduler)

| Error Code | Category | Severity | BC Anchor | RetryHint | Message Format |
|-----------|----------|----------|-----------|-----------|---------------|
| E-CRON-001 | VAL | broken | BC-2.12.004 | Never | `AssistantNotFoundAtFiring: cron schedule '<cron_id>' fired but assistant '<assistant_id>' no longer exists` |
| E-CRON-002 | VAL | broken | BC-2.12.004 | Never | `InvalidCronExpression: field '<field>' value '<value>' is out of range — <reason>` |
| E-CRON-003 | POLICY | degraded | BC-2.12.004 | Later | `ScheduleQueueFull: cron schedule '<cron_id>' firing skipped; queue depth <queue_depth> exceeds max_queue_depth` |

### Component: MEMORY (ferrochain-memory)

| Error Code | Category | Severity | BC Anchor | RetryHint | Message Format |
|-----------|----------|----------|-----------|-----------|---------------|
| E-MEMORY-001 | VAL | broken | BC-2.15.001 | Never | `EmbeddingBackendNotConfigured: vector_search requires an embedding backend; none is configured` |
| E-MEMORY-002 | DURABILITY | broken | BC-2.15.001 | Never | `StorageFull: memory backend '<backend>' at '<path>' has no remaining capacity` |
| E-MEMORY-003 | POLICY | broken | BC-2.15.002 | Never | `ScopeAccessDenied: caller identity '<caller_identity>' cannot write to <requested_scope> — cross-owner lateral access denied` |
| E-MEMORY-004 | VAL | broken | BC-2.15.002 | Never | `NoScopeContext: memory scope resolution requires an active RunnableConfig session context; none is available` |
| E-MEMORY-005 | DURABILITY | broken | BC-2.15.003 | Never | `ErasurePartialFailure: GDPR erasure for user '<user_id>' partially completed; rolled back — <reason>` |
| E-MEMORY-006 | POLICY | broken | BC-2.15.003 | Never | `InsufficientPrivilege: operation '<operation>' requires AdminContext; caller has <caller_privilege>` |

### Component: BUDGET (ferrochain-graph budget governance subsystem)

> **Budget namespace reconciliation note (ADV-P1D-PASS-2 fix, 2026-07-14):** BCs BC-2.10.001–004
> were authored before a BUDGET component section existed, using `E-BUDGET-NNN` codes that had no
> taxonomy home. E-GRAPH-005 (BudgetCeiling) was the taxonomy's previous attempt to cover budget
> errors within the GRAPH component; it is now retired above. Budget governance errors use the
> BUDGET component (a subsystem of ferrochain-graph, following the RETRY/CRON pattern for
> intra-crate subsystems). Category decision: BudgetCeilingReached is POLICY (budget ceiling is a
> policy constraint that rejects the operation — matches POLICY definition verbatim); JournalWriteFailed
> is DURABILITY (storage I/O failure on the evidence journal write path).

| Error Code | Category | Severity | BC Anchor | RetryHint | Message Format |
|-----------|----------|----------|-----------|-----------|---------------|
| E-BUDGET-001 | POLICY | broken | BC-2.10.003 | Never | `BudgetCeilingReached: run '<run_id>' halted; token budget of <limit> exceeded at <actual> tokens` |
| E-BUDGET-002 | DURABILITY | broken | BC-2.10.002 | Never | `JournalWriteFailed: budget evidence journal write failed for run '<run_id>': <backend_error>` |

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
