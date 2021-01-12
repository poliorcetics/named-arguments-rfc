# Rationale and alternatives
[rationale-and-alternatives]: #rationale-and-alternatives

- Why is this design the best in the space of possible designs?
- What other designs have been considered and what is the rationale for not choosing them?
- What is the impact of not doing this?

## Alternatives

### Anonymous types (Structural Records) and type deduction

```rust
fn foo<T>({ len: usize, f: Fn(T) -> u32 }) -> u32;
```

This does not allow to differentiate a public and a private name, removes
ordering and adds boilerplate (`{}`). In case of type deduction
(`foo(_ { a: 3, b: 6 })`) the boilerplate is even worse, it asks for an entirely
new type, which must now be made public and documented if your function is
public.

### Builder pattern

```rust
let mut vec = vec![1];
vec.reserve_exact(10);
```

Is this parameter `additional` or `total` capacity ? The name of the method is
quite unclear here, and a builder would be very heavy, as would a new type.

On the other hand you can have a builder make use of named arguments:

```rust
let my_conn = ConnectionBuilder::new()
    .delay(seconds: 4)
    .port(443)
    .build();
```

### Named types

The examples above about `Vec::reserve_exact` and `fn foo<T> ...` are applicable
here too.

### Do nothing

Without named arguments Rust is already a very good language. Named arguments
are a nice feature and can help with safety and soundness but they are not the
greatest thing since sliced bread either and Rust can live without them, as it
already has for years.

This has been rejected for several reasons in this RFC, reasons that have been
explained earlier (safety, soundness) but also because the alternatives are
either insufficient or too heavy-handed.
