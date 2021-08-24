# Future possibilities

Think about what the natural extension and evolution of your proposal would be and how it would
affect the language and project as a whole in a holistic way. Try to use this section as a tool to
more fully consider all possible interactions with the project and language in your proposal. Also
consider how the this all fits into the roadmap for the project and of the relevant sub-team.

This is also a good place to "dump ideas", if they are out of scope for the RFC you are writing but
otherwise related.

If you have tried and cannot think of any future possibilities, you may simply state that you cannot
think of anything.

Note that having something written down in the Future Possibilities section is not a reason to
accept the current or a future RFC; such notes should be in the section on motivation or rationale
in this or subsequent RFCs. The section merely provides additional information.

## Allow keywords

`write(in db: Database)` is not possible with the design proposed in this RFC.

We could allow keywords to be used in named arguments since they can never be ambiguous in such a
case, with the exceptions of `pub`, `ref` and `mut`, thanks to the:

- two identifiers back to back at the declaration point
- `:` separating the argument name from the expression at the call point

Using keywords would be prohibited with `pub` since it would allow the following:

```rust
fn with_kw_as_named(pub in: String) {
    // ERROR: `in` would be a variable here
}
```

## Variadic functions

In Swift, named arguments arguments are used as boundaries to allow for functions with several
variadic parameters. While such functions do not yet exist in Rust (and there is no hard requirement
for them to do), this opens up the possibility:

```rust
// Some made-up syntax, not a proposition
fn add_sub_several(pub add: usize..., pub sub: usize...) { /* ... */ }

add_sub_several(add: 1, 2, 4, sub: 3, 5);
```

## Specialization and named arguments in closures

In [Interaction with traits][interaction-with-traits], it was said the following case cannot be
differentiated based on named arguments alone:

```rust
struct Closure<F> {
    data: (u8, u16),
    func: F,
}

impl<F> Closure<F>
    where F: Fn(arg: &(u8, u16)) -> &u8,
{
    fn call(&self) -> &u8 {
        (self.func)(&self.data)
    }
}
```

One could imagine a world where specialization allows this. This is out of scope for this RFC.
