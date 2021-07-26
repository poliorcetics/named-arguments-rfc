# Drawbacks

[drawbacks]: #drawbacks

Why should we _not_ do this?

## Closures

Enforcing named arguments in closure without implicit casting would very heavy for users: it would
force the following:

```rust
// One unnamed argument must be passed
fn take_closure_with_param<T>(f: Fn(T)) { /* ... */ }

let cls = |param1| some_other_function(public_name: param1);
take_closure_with_param(cls);

// OR

take_closure_with_param(|param1| some_other_function(public_name: param1));
```

Instead of the concise:

```rust
take_closure_with_param(some_other_function);
```

That point can be argued for and against though, and it can rightly be argued that implicitly
casting argument names is wrong. I believe a more nuanced approach, through a lint, could be taken,
which would allow people to choose whether to enforce explicitness or not, just like the
`unsafe_op_in_unsafe_fn` lint does.

It must be noted this would always stay possible and could again be linted for:

```rust
take_closure_with_param(some_other_function(public_name:));
```
