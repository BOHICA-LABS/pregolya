// BC-2.14.003 {PC-004}/{EC-007} live-violation fixture (MED-4 fix):
// .unwrap() inside a macro argument (format!) must be FLAGGED.
//
// The no-panic gate must recurse into macro token streams to catch .unwrap()
// calls that are invisible to syn's normal AST visitor. format! is a common
// macro where .unwrap() in the arguments is easy to miss.
pub fn format_value(opt: Option<i32>) -> String {
    format!("{}", opt.unwrap())
}
