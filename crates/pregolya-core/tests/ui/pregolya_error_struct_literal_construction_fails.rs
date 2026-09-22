// Compile-fail: external struct-literal construction of PregolyaError is barred.
// BC-2.14.001 {PC-008} clause 1.
// Note: private fields (code, source) may produce E0451; #[non_exhaustive] independently
// produces E0639. Both mechanisms bar construction. This test captures the actual error.
fn main() {
    let _err = pregolya_core::PregolyaError {
        component: pregolya_core::Component::Core,
        category: pregolya_core::Category::Internal,
        retry_hint: pregolya_core::RetryHint::Never,
        message: "test".to_string(),
    };
}
