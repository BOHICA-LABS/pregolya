# BC Behavioral-Completeness Scan — Phase-2 (D-270, 2026-08-25)

Frozen HEAD scanned: factory-artifacts ed59cd9 (== pre-hardening baseline).
Method: 7 fresh-context reviewers, all 133 BCs. Result: 47 gaps (4 HIGH / 31 MED / 12 LOW).
Upstream engine issue: drbothen/vsdd-factory#785 (add bc-completeness-scan as a standard step).
Status: prior 3-CLEAN (D-269) SUPERSEDED; PO propagation fan-out pending → re-adversarial-3-CLEAN + consistency audit → Phase-2 gate.

## Architect design decisions (recorded in ADRs; PO propagates into BCs)
- D1 MMR (ADR-014 §Decision 7): Carbonell–Goldstein argmax `λ·cos(q,d) − (1−λ)·max_{d'∈S}cos(d,d')` over fetch_k pool; cosine; empty-set=0.0; lowest-index tie-break; pool-exhaustion→partial return. PO: propagate to BC-2.20.003 PC-003 + BC-2.21.001 PC-002; update BC-2.21.003 VP-2.21.003-C to cite formula + score-sequence.
- D2 multitask (ADR-028 D1–3): interrupt & rollback → pre-empted run `cancelled`; rollback rewinds to latest_completed_checkpoint_id; enqueue FIFO, max_queued_runs=10, HTTP 429 + NEW E-SERVER-019 RunQueueFull (POLICY, RetryHint Later; SERVER 18→19). PO: propagate to BC-2.12.003 PC-004 + mint E-SERVER-019 in error-taxonomy.
- D3 delete_threads cascade (ADR-028 D4): atomic-abort, HTTP 409, reuse E-SERVER-008. PO: fix BC-2.12.002 EC-003.
- D4 delete idempotency (ADR-014 §Decision 8): nonexistent ID → Ok(()) trait-mandated. PO: fix BC-2.21.001 EC-003.
- D5 idempotency TTL (ADR-028 D5): TTL-from-submission (24h); in-window resubmit → cached response; operator note TTL>max-run-duration. PO: fix BC-2.12.006 EC-001.

## Gap inventory by cluster (PO fan-out = 7 clusters; each edits only its ss-NN BC files; reuse existing E-codes where valid; NEW codes collected + minted in one coordination pass before commit; flag any story-AC/POL-8 propagation)

### SS-01..03 (7: 0H/5M/2L)
- BC-2.01.001 MED: strict-vs-lenient deserialization has an outcome (E-CORE-001) but no entry mechanism — name the selecting API + add PRE.
- BC-2.01.002 MED: INV-002 accepts "chat" arbitrary-role discriminant but no ChatMessage variant behavior/fields specified — add PC/EC or remove from accepted set.
- BC-2.01.008 MED: declares ST test-type + safetee anchor (ADR-026 §D4) but specifies only invoke — add RunnableAssign streaming PC + TV.
- BC-2.02.001 MED: successful Command return (valid goto + embedded update) unspecified (only failing EC-004) — add PC or cross-ref Command BC.
- BC-2.02.005 MED: side-effecting path_fn declared "not defined behavior" — decide (writes dropped OR structured error).
- BC-2.02.005 LOW: conflicting multi-edge union (End vs NodeName) unresolved.
- BC-2.01.003 LOW: default-stream item type + behavior on invoke Err unspecified.

### SS-04..06 (6: 0H/4M/2L)
- BC-2.04.001 MED: async put_writes join-failure path (EC-002 covers only sync) — add async-join-failure EC.
- BC-2.04.005 MED: pending_writes reapply read/deserialize failure (EC-006 covers only get_tuple) — add EC.
- BC-2.04.008 MED: search_history tool error surface (ToolOutput::Error vs run-halt) unspecified.
- BC-2.05.004 MED: Command update(unknown-channel)/goto(nonexistent)/resume(unmatched interrupt_id) failure paths.
- BC-2.06.002 LOW: resume-run parent_ids "impl-choice, must document in ADR" — decide or cite concrete ADR.
- BC-2.06.006 LOW: compact-fail × hard-ceiling — cross-BC (SS-10) wave-gate note, not in-cluster.

### SS-07..08 (4: 0H/4M/0L)
- BC-2.08.010 MED: ToolRegistrationError::DuplicateName uncoded — assign taxonomy code or cite owner BC.
- BC-2.08.012 MED: reserved-name warning-vs-error — decide hard compile error + TV.
- BC-2.08.013 MED: multi-tool-call mixed-validity — specify fail-fast (whole response Err E-PROV-009, no partial ToolCall list).
- BC-2.08.001 MED: protocol-malformed v3 stream runtime outcome — typed Err (distinct from E-PROV-003 transport) + no-panic.

### SS-09..11 (5: 0H/2M/3L)
- BC-2.10.005 MED: OnWatermark fraction domain (>1.0/negative/NaN) — construction Err + TV (silent-misconfig otherwise).
- BC-2.09.007 MED (SECURITY): credential-message sanitization — INV-003 mandates it but PCs forward verbatim ("best-effort v1" hedge) — define concrete redaction step in PC + TV; remove hedge.
- BC-2.09.006+007 LOW: malformed/unparseable JSON-RPC request (-32700/-32600) on server-receive.
- BC-2.09.007 LOW: result_text JSON-vs-plaintext selection rule.
- BC-2.11.006 LOW: "tracked separately (cascading log failure)" — specify observable (counter/metric) or unobservable-by-design.

### SS-12..14 (10: 2H/6M/2L)
- BC-2.12.003 HIGH: propagate ADR-028 D1–3 (multitask interrupt/rollback/enqueue) + mint E-SERVER-019.
- BC-2.12.002 HIGH: propagate ADR-028 D4 (delete_threads atomic-abort) — fix EC-003.
- BC-2.12.001 MED: POST /state failure paths (invalid as_node, malformed delta, thread-not-found).
- BC-2.12.002 MED: empty graph_id PATCH — assign E-code + status (VAL/400).
- BC-2.12.004 MED: invalid RunnableConfig at schedule creation — error code + status.
- BC-2.12.006 MED: propagate ADR-028 D5 (TTL-from-submission) + operator note.
- BC-2.13.002 MED: process backend execute failure (spawn failure, non-zero exit) codes.
- BC-2.13.001 MED: runtime resource-limit breach (memory_bounded=true) outcome — E-SBXD code or cite.
- BC-2.13.004 LOW: non-escape canonicalize I/O error (perm-denied/ELOOP) catch-all.
- BC-2.12.006 LOW: rate-limit 429 missing E-SERVER code.

### SS-15..18 (9: 1H/6M/2L)
- BC-2.18.004 HIGH (SECURITY): FewShotExamples injection arm — add PC-005 E-TMPL-001 fail-closed for the 3rd arm + extend VP-006 scope to all 3 arms + TV (or explicit in-BC delegation to BC-2.18.003 with VP-006 scope statement).
- BC-2.15.001 MED: hybrid_search cross-metric ranking/fusion rule (recency rank vs cosine) — define; add TV.
- BC-2.15.003 MED: GdprErasureReceipt PC-004 missing unattributed_session_count field (EC-004 claims it).
- BC-2.15.003 MED: audit-log write partial-failure after tier-deletion commit — outcome.
- BC-2.15.004 MED: SkillStore name-collision "registration time" undefined on read-only BC — define registration point + error code.
- BC-2.15.005 MED: MemoryWriteRequest::Replace scanner behavior (which field(s) scanned; Transform on new_value) — add PC/EC + TV.
- BC-2.16.001 LOW: retry-counter reset hedge — state resets to 0 on success.
- BC-2.18.003 MED: FewShot output provenance (highest_trust_level of generated pair messages) unspecified.
- BC-2.15.001 LOW: vector-search embedding-dimension mismatch — EC + code, or validate-at-write.

### SS-19..23 (6: 1H/4M/1L)
- BC-2.22.002/003 HIGH: provider HTTP-status error codes (429/5xx→E-PROV-008, 401→E-PROV-004, conn→E-PROV-012) + add missing OpenAI auth/connection ECs to BC-2.22.002.
- BC-2.20.003 + BC-2.21.001 MED: propagate ADR-014 §D7 MMR formula; update BC-2.21.003 VP-2.21.003-C.
- BC-2.21.004 MED: InMemory post-filter fetch strategy ("up to some internal fetch limit") — define (scan-all vs multiplier).
- BC-2.21.001 MED: propagate ADR-014 §D8 delete idempotency (EC-003 → Ok(())).
- BC-2.23.003 + BC-2.23.005 MED [process-gap]: tool config-validation error codes (fuzzy_threshold, zero-duration) + BashTool max_output_bytes=0 rule + TV.
- BC-2.22.001 LOW: embed_query "declared dimension" not exposed by trait — narrow guarantee to zero-length OR add dimension accessor.

## Cross-BC / wave-gate observations (not in-cluster BC fixes)
- BC-2.06.006 compact-fail vs SS-10 hard-ceiling OnCeiling::Halt interaction.
- BC-2.21.002 add_documents write-time dimensionality consistency (marginal; single injected Embeddings).
