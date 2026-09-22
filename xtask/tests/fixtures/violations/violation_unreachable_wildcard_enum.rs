// POL-31 live-violation fixture (BC-2.14.003 EC-004/EC-007, AC-017):
// An enum match with explicit `Enum::Variant` arms AND a `_ => unreachable!()`
// wildcard arm MUST be FLAGGED by check-no-panic.
//
// EC-004 / EC-007: `_ => unreachable!()` is a latent panic path under enum
// evolution regardless of whether the preceding arms use `::` -qualified patterns.
// Red-gate provenance: authored when the removed `has_qualified_path_before` heuristic
// exempted enum-arms-before-wildcard; the shipped syn/AST scanner flags any
// `_ => unreachable!()` wildcard regardless of the preceding named-variant arms —
// their presence only confirms current exhaustiveness, not future-proof safety.
// A new enum variant added downstream makes the `_` arm reachable in production.
//
// Exemption 1 (BC-2.14.003 §EC-007) applies ONLY when unreachable!() appears in
// an EXPLICIT NAMED arm (e.g. `Status::Closed => unreachable!(...)`) with no
// wildcard `_` arm present. A wildcard `_ => unreachable!()` arm is always a
// latent panic path and must always be flagged.
pub enum Status {
    Active,
    Inactive,
    Pending,
}

pub fn status_label(s: &Status) -> &'static str {
    match s {
        Status::Active => "active",
        Status::Inactive => "inactive",
        Status::Pending => "pending",
        _ => unreachable!("EC-004: _ arm with enum::variant arms must still be flagged"),
    }
}
