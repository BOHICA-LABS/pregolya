// BC-2.14.005 {PC-006} live-violation fixture (F-P2-L05 fix):
// pub(crate) struct with Debug derive must be flagged.
// The gate must handle pub(crate) visibility modifiers, not just plain pub.
#[derive(Debug)]
pub(crate) struct InternalAuthToken(String);
