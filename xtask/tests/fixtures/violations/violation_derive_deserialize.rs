// Violation fixture: #[derive(Deserialize)] on a credential-sentinel struct.
// deny-bare-api-key gate must flag this (BC-2.14.005 {PC-006}, BC-2.14.006).
// Deserialize bypasses new() validation — arbitrary strings including empty/whitespace
// could be deserialized directly without going through the validated constructor.
#[derive(Deserialize)]
pub struct FooApiKey(String);
