# Guide-level explanation

[guide-level-explanation]: #guide-level-explanation

Explain the proposal as if it was already included in the language and you were teaching it to
another Rust programmer. That generally means:

- Introducing new named concepts.
- Explaining the feature largely in terms of examples.
- Explaining how Rust programmers should _think_ about the feature, and how it should impact the way
  they use Rust. It should explain the impact as concretely as possible.
- If applicable, provide sample error messages, deprecation warnings, or migration guidance.
- If applicable, describe the differences between teaching this to existing Rust programmers and new
  Rust programmers.

For implementation-oriented RFCs (e.g. for compiler internals), this section should focus on how
compiler contributors should think about the change, and give examples of its concrete impact. For
policy RFCs, this section should provide an example-driven introduction to the policy, and explain
its impact in concrete terms.

---

This section will explain how to declare and use named arguments as a teacher may explain
mathematics: it will present the concepts while abstracting away much of the reasoning, which is
detailed more thouroughly in other sections (see [Reference-level
explanation][reference-level-explanation])

## How do I declare a function with named arguments ?

There are two way to mark an argument as _named_ when declaring a function (or method):

- With the `pub` keyword.
- With another identifier.

The following example presents both methods in their simplest form. Further examples will explain
how edge cases are handled.

```rust
pub struct Database;
pub struct RegistrationError;

pub fn register(
    pub name: String,
    pub surname: String,
    to db: Database
) -> Result<(), RegistrationError> {
    /* ... */
}
```

The `pub name: String` part marks the binding `name` as public: it must be provided when calling the
function and can be used inside the function too.

The `to db: Database` part marks the binding `to` as public and the binding `db` as internal: `to`
must be used when calling the function and cannot be used inside its definition. `db` is in the
opposite situation: it cannot be used outside the function's definition.

### What about `self` ?

The previous example works but it's contrived and not very idiomatic. It could instead be rewritten
like this:

```rust
pub struct Database;
pub struct RegistrationError;

impl Database {
    pub fn register(&self, pub name: String, surname: String) -> Result<(), RegistrationError> { /* ... */ }
}
```

This example raises a question: what about the `&self` part ? Can it be named ? Can it be marked
with the `pub` keyword ?

**No**, it cannot. Named arguments are here to increase clarity. Call to methods are already as
clear as possible: either done through
`my_db.register(name: "Alexis".into(), surname: "Poliorcetics".into())`, with the `.` clearly
marking the called function and the caller or through the qualified syntax in which the type (or
trait) cannot be omitted:
`Database::register(my_db, name: "Alexis".into(), surname: "Poliorcetics".into())`.

It is possible to create module named `Database` and write a `register` function in it like this:

```rust
mod Database {
    pub struct Database;
    pub struct RegistrationError;

    pub fn register(
        into db: Database
        pub name: String,
        pub surname: String,
    ) -> Result<(), RegistrationError> {
        /* ... */
    }
}
```

This can then be called as:
`Database::register(into: my_db, name: "Alexis".into(), surname: "Poliorcetics".into())` but I
cannot think of a situation where this is preferable to an `impl` block and a singleton pattern.

### Can I use `pub(something)` ?

**No**, named arguments are always as public as the function they belong to. They must be used
anytime the function is called so it is not possible to limit them to an arbitrary scope that is
different from the function's.

### Why use `pub` and not just write the identifier twice ?

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

## How do I use a function with named arguments ?

This has been hinted at in the previous subsection, so here is the syntax, using the same examples
as before:

```rust
// Free function
register(name: "Alexis".into(), surname: "Poliorcetics".into(), to: my_db);

// '.' call
my_db.register(name: "Alexis".into(), surname: "Poliorcetics".into());

// Qualified call
Database::register(my_db, name: "Alexis".into(), surname: "Poliorcetics".into());
```

Functions and methods are called as usual, the parameters can be any expression that eventually
resolves to the correct type for the argument, but there is the identifier and a `:` before said
expression.

## Can I mix named and unnamed arguments ?

**Yes**, without any restrictions (beside the one on `self` in methods):

```rust
// Calling with an unnamed and a named argument.
my_vec.insert(2, at: 3)

// Declaring a function which mixes named and unnamed arguments in some arbitrary order.
fn mix_and_match(pub named: usize, unnamed: usize, public hidden: usize) { /* ... */ }
```

## Can I reorder named arguments ?

**No**. Just like unnamed arguments, named arguments are also position-based and cannot be reordered
when calling: `register(name:, surname:)` cannot be called as `register(surname:, name:)`.

Reordering them at the definition site is an API break, just like reordering unnamed arguments is an
API break already.

## How do named arguments interacts with closures ?
