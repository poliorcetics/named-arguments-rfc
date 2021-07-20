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
explanation][reference-level-explanation]). It is divided into three parts: declaring, calling and
other details.

## Declaring a function using named arguments

There are two way to mark an argument as _named_ when declaring a function (or method):

- With the `pub` keyword (only when the binding is **not** a pattern).
- With another identifier (that **cannot** be a pattern itself).

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

### Declaring closures with named arguments

### When using `self`

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
cannot think of a situation where this is preferable to an `impl` block and a singleton pattern
using some `lazy_static` or `once_cell`.

### When using `mut` or `ref`

`mut` cannot be an identifier for an argument but it can be used by a function to avoid a
`let mut arg = arg;` inside. This capability does not go away with named arguments.

- When using `pub`; `mut` is placed after it to follow the current syntax of Rust where the
  visibility is always first: `fn register(pub mut name: String)`.
- When using an identifier, `mut` comes first: `fn new_db(mut named name: String) -> Database`.

The exact same rules apply for `ref`.

If _both_ `ref` and `mut` are present, they use the same order as today: `ref mut`, and with `pub`:
`pub ref mut`.

### When using a pattern

- `pub` **cannot** be used here since there is no identifier for it to expose.
- The identifier **cannot** be a pattern. Its only use is as a public facing name, it does not
  destructure anything nor can be used as a binding inside the function.
- The identifier is placed before the pattern as shown in the example below:

```rust
struct Point { x: f32, y: f32 }

impl Point {
    fn opposite(&self, centered_on Self { x, y }: Self) -> Self {
        Self {
            x: 2.0 * x - self.x,
            y: 2.0 * y - self.y,
        }
    }
}
```

### Combining patterns and `mut`/`ref`

This has the same behavior as current Rust: it is impossible to mark all the bindings in a pattern
as mutable at once:

```rust
// ERROR
impl Point {
    fn opposite(&self, mut Self { x, y }: Self) -> Self {
    //                 ^^^ does not compile
        Self {
            x: 2.0 * x - self.x,
            y: 2.0 * y - self.y,
        }
    }
}

// OK
impl Point {
    fn opposite(&self, Self { mut x, y }: Self) -> Self {
        Self {
            x: 2.0 * x - self.x,
            y: 2.0 * y - self.y,
        }
    }
}
```

### Can I use `pub(something)` ?

**No**, named arguments always have the exact same visibility as the function they belong to. They
must be used anytime the function is called so it is not possible to limit them to an arbitrary
scope that is different from the function's.

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

## Calling a function with named arguments

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

### Calling a closure with named arguments

## Other points

### Using named argumnts with `trait`s

Named arguments are fully usable in `trait`s and types implementing those must respect the _public_
facing name of the argument, the private one can be modified:

```rust
trait Connection {
    fn connect(&mut self, pub port: usize);
}

struct Dummy;

impl Connection for Dummy {
    fn connect(&mut self, port _: usize) {
    //                    ^^^^   Public name is the same
    //                         ^ Name has been changed internally
    }
}

fn create_conn<T: Connection>(t: &mut T) {
    t.connect(port: 443)
    //        ^^^^ Public name declared by trait is used in call.
}
```

### Overloading a function's name with named arguments

Named arguments also introduce a limited form a function overloading that is easy to check for both
a human and the compiler and can be applied to profit plainly from heavily used function names like
`new`. This overloading is based on both the function's name and the public names of all the named
arguments, ensuring two overloaded functions side by side cannot be mistaken for one another: the
information is always present, even when reading code without tooling to show type and name hints.

In the example below, calling `my_result.ok()` and `my_result.ok(or: default_value)` would call two
different functions. The third function would be banned because it uses the same public name as the
second one.

```rust
impl<T, E> Result<T, E> {
    pub fn ok(self) -> Option<T> {
        match self {
            Ok(t) => Some(t),
            Err(e) => None,
        }
    }

    pub fn ok(self, or fallback: T) -> T {
        match self {
            Ok(t) => t,
            Err(_) => fallback,
        }
    }

    // ERROR
    pub fn ok<U>(self, or replacement: U) -> T where U: Into<T> {
    //     ^^----------^^----------------
    //     A function using this name and this named argument already exists.
        match self {
            Ok(t) => t,
            Err(_) => replacement.into(),
        }
    }
}
```

### Can I mix named and unnamed arguments ?

**Yes**, without any restrictions (beside the one on `self` in methods):

```rust
// Calling with an unnamed and a named argument.
my_vec.insert(2, at: 3)

// Declaring a function which mixes named and unnamed arguments in some arbitrary order.
fn mix_and_match(pub named: usize, unnamed: usize, public hidden: usize) { /* ... */ }
```

### Can I reorder named arguments when calling ?

**No**. Just like unnamed arguments, named arguments are also position-based and cannot be reordered
when calling: `register(name:surname:)` cannot be called as `register(surname:name:)`.

Reordering them at the definition site is an API break, just like reordering unnamed arguments is an
API break already.

### Documenting named arguments

Talking about functions using named argument would use `register(name:surname:)`, not just
`register()`. This would allow differentiating overloads clearly.

`rustdoc` shows the internal name of arguments already when generating documentation for Rust code.
While leaky, this is very useful to understand some parameters and have names to refer to in textual
documentation, like for [`f32::mul_add`][mul-add], and removing it to instead show only named
arguments would be very detrimental to the user experience.

The proposed change is the following:

- Insert the keyword `pub` before arguments that are public and declared with `pub`:
  `fn register(pub name: String)`.
- Insert both the public and private name for arguments that use an identifier:
  `fn opposite(&self, centered_on _: Self) -> Self`. This is taken from how Swift
  [does it](https://swiftdoc.org/v5.1/type/bool/).
- Keep the behavior of showing `_` when a pattern was used as the argument (like above).
- Keep hiding `mut` and `ref` like currently done.

[mul-add]: https://doc.rust-lang.org/stable/std/primitive.f32.html#method.mul_add
