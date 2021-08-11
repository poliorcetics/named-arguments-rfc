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
