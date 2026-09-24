// Violation fixture: impl Display for a credential-sentinel struct.
// deny-bare-api-key gate must flag this (BC-2.14.005 {PC-006}, {INV-002}).
// Display output is invoked by format!("{}", key) — credential values must
// not appear in any format output.
pub struct OpenAiApiKey(String);

impl std::fmt::Display for OpenAiApiKey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}
