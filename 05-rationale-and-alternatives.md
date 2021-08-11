# Rationale and alternatives

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

### Allowing overloading

The form of overload proposed would notably allow moving the standard library mostly without
troubles: `Option::ok_or` could continue to exist and be deprecated in favor of `Option::ok(or:)`.

There would probably be errors, especially around functions passed as closures in some places, when
the current argument is `Option::or` for example: it could refer to
`Option::or(self, optb: Option<T>)` or `Option::or(self, else f: F)`.

One source-preserving solution to this is to add either a rule saying the one without names is the
default one or an attribute that marks a method as the default one when ambiguous. Type errors would
then catch the wrong cases, though there are probably situations where that woulnd't work.

The non-source-preserving solution is for the compiler to propose fixes such as `Option::or(_:_:)`
or to introduce unambiguous closures itself: `|a0, a1| a0.or(a1)`.

As the main purpose of named arguments is clarity, the preferred solution would to ask for
clarification when the situation is ambiguous. This has the huge disavantage of gating named
arguments to a new edition and basically banning them from the standard library since code using
previous editions has to compile with new versions of Rust.

To ensure named arguments are accessible for all, passing `Option::or` (or any other overloaded)
method would then always resolve to `Option::or(self, optb: Option<T>)`, the one without named
arguments and the compiler would complain if this form is used for a method taking named arguments,
even if currently unambiguous.

### Disallowing keywords

`for`, `in`, `as` are not allowed by this RFC in the position of named arguments. This is for
simplicity and clarity: Rust developers and tooling expect them to be keywords, changing this
expectation while introducing such a big change to the language would probably be very confusing for
some time. They could be allowed later, once named arguments have been here for some time and people
have had time to get used to them.

They could also be authorised directly to allow for their use in the standard library for example,
if we find several cases where they would be the best fit.

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

## Alternatives

### Completely disallow named arguments for `#[no_mangle]` and `extern`

To ensure such functions are still first-class citizens in Rust, this has been rejected. It may
prove too difficult to implement or too confusing and named arguments could be completely
deactivated for them.

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
