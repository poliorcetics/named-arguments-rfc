# Rationale and alternatives

[rationale-and-alternatives]: #rationale-and-alternatives

- Why is this design the best in the space of possible designs?
- What other designs have been considered and what is the rationale for not choosing them?
- What is the impact of not doing this?

## Rationale

There have been several choices made in this RFC that need justification. In no particular order:

- Using `:`
- Using `pub` only sometimes
- Allowing overloading through named arguments
- Not allowing keywords in the public name (`for`, `in`, `as` especially)

TODO: explain choices

## Alternatives

### Always use `pub`

In the Guide Level Explanation, is it said:

> Using `fn register(pub to db: Database)` is an error.

It can be argued that always using `pub` even when an alternate identifier is provided is both
easier for the compiler and clearer for readers of the function. This has not been kept to avoid
_too much informations_ in function's declaration. If people feel it would be clearer, that can
certainly be changed.

We should not allow both though, it would be redundant and would probably confuse people used to one
syntax but not the other.

### Never use `pub` and write the identifier twice

`fn register(name name: String)` certainly works and is not banned but it is rather redundant and
raises a question: did the function writer intend to write `pub` or use a different name and simply
forgot ? Marking such cases as `pub` makes the original intent clear and reminds the developer that
modifying the name is an API break.

`pub` is not asked for when the two bindings are differents because the situation makes it clear
already: two identifiers cannot be placed that way next to each other without an operator or a comma
anywhere else in normal Rust (it can happen in macros though). Therefore the only possible case is
that one name is public and the other is private. Using the first as the public name is then
logical: it is in the position of the `pub` keyword, taking advantage of the similar placement with
a similar functionnality, which is important for consistency.

### Enforce named arguments for closures

Enforcing named arguments in closure without implicit casting would very heavy for users: it would
force the following:

```rust
fn take_closure_with_param<T>(f: Fn(T)) { /* ... */ }

let cls = |param1| some_other_function(public_name: param1);
take_closure_with_param(cls);

// Or
take_closure_with_param(|param1| some_other_function(public_name: param1));
```

Instead of:

```rust
take_closure_with_param(some_other_function);
```

That point can be argued for and against though, and it can rightly be argued that implicitly
casting argument names is wrong. I believe a more nuanced approach, through a lint, could be taken,
which would allow people to choose whether to enforce explicitness or not, just like the
`unsafe_op_in_unsafe_fn` lint does.

It must be noted this would always stay possible:

```rust
take_closure_with_param(some_other_function(public_name:));
```

Another argument against this behavior is clarity: implicitly casting argument names to fit a
closure expectation can be see as very very wrong. This argument though, forgets that closure are
used very locally and often as parameters to other functions and closure, ensuring a form of clarity
through context that is not available to functions far removed from their call site.

### Anonymous types (Structural Records) and type deduction and named types

```rust
fn foo<T>({ len: usize, f: Fn(T) -> u32 }) -> u32;
```

This does not allow to differentiate a public and a private name, removes ordering and adds
boilerplate (`{}`). In case of type deduction (`foo(_ { a: 3, b: 6 })`) the boilerplate is even
worse, it asks for an entirely new type, which must now be made public and documented if your
function is public.

### Builder pattern

```rust
let mut vec = vec![1];
vec.reserve_exact(10);
```

Is this parameter `additional` or `total` capacity ? The name of the method is quite unclear here,
and a builder would be very heavy, as would a new type.

On the other hand you can have a builder make use of named arguments:

```rust
let my_conn = ConnectionBuilder::new()
    .delay(seconds: 4)
    .port(443)
    .build();
```

### Do nothing

Without named arguments Rust is already a very good language. Named arguments are a nice feature and
can help with safety and soundness but they are not the greatest thing since sliced bread either and
Rust can live without them, as it already has for years.

This has been rejected for several reasons in this RFC, reasons that have been explained earlier
(safety, soundness) but also because the alternatives are either insufficient or too heavy-handed.
Named arguments have also been on the "nice-to-have-but-needs-design" list for years. This RFC is
just the latest attempt at the "design" part.
