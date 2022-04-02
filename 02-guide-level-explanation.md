# Guide-level explanation

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

Named arguments are the ability to call a function, method or closure while precising the
caller-facing name of the arguments, greatly improving clarity in many situations. Of course
functions where the arguments are already clear do not have to use them: `sin(x: x)` would be
ridiculous and redundant.

This section will explain how to declare and use named arguments as a teacher may explain
mathematics: it will present the concepts while abstracting away much of the reasoning, which is
detailed more thoroughly in other sections (see [Reference-level
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

Using `fn register(pub to db: Database)` is an error.

Using `fn register(pub(in path) name: String)` is also an error: named arguments always have the
exact same visibility as the function they belong to. They must be used anytime the function is
called so it is not possible to limit them to an arbitrary scope that is different from the
function's.

### Declaring closures with named arguments

Just like regular function, it is possible to declare closures with named arguments:

```rust
pub struct Point { x: f32, y: f32 }

impl Point {
    // Using `Fn` form
    pub fn strange_operation(&self, f: impl Fn(add: f32, mul: f32) -> (f32, f32)) -> (f32, f32) {
    //                                         ^^^       ^^^ named arguments declared here
        f(add: self.x, mul: self.y)
    //    ^^^          ^^^ and used here
    }
}

// Using closure form
let closure = |pub add, other arg| { (add + 42.0, arg * 42.0) };
```

Just like functions, `add` and `arg` must be used inside the function when declared, `other` is not
available.

### When using `self`

The previous example about `register` works but it's contrived and not very idiomatic. It could
instead be rewritten like this:

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

### When using `mut` or `ref`

`mut` cannot be an identifier for an argument but it can be used by a function to avoid a
`let mut arg = arg;` inside. This capability does not go away with named arguments.

- When using `pub`; `mut` is placed after it to follow the current syntax of Rust where the
  visibility always comes first: `fn register(pub mut name: String)`.
- When using an identifier, `mut` comes first: `fn new_db(mut named name: String) -> Database`.

The exact same rules apply for `ref`.

If _both_ `ref` and `mut` are present, they use the same order as today: `ref mut`, and with `pub`:
`pub ref mut`.

### When using a pattern

Irrefutable patterns can be used in functions arguments today, and just like `self`, they raise some
questions.

- `pub` **cannot** be used here since there is no identifier for it to expose.
- The identifier **cannot** be a pattern. Its only use is as a public facing name, it does not
  de-structure anything nor can be used as a binding inside the function.
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
    fn opposite(&self, mut centered_on Self { x, y }: Self) -> Self {
    //                 ^^^ does not compile
        Self {
            x: 2.0 * x - self.x,
            y: 2.0 * y - self.y,
        }
    }
}

// OK
impl Point {
    fn opposite(&self, centered_on Self { mut x, y }: Self) -> Self {
        Self {
            x: 2.0 * x - self.x,
            y: 2.0 * y - self.y,
        }
    }
}
```

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

You cannot omit named arguments, even when the passed expression is exactly the same as the
identifier: `my_db.register(name: name)` cannot be shortened to `my_db.register(name)`.

### Calling a function with named arguments indirectly

All examples until now have always called the function (or closure) directly, but Rust also allows
us to pass functions and closures as arguments. Below is how named arguments behave in such a case:

```rust
pub struct Point { x: f32, y: f32 }

impl Point {
    pub fn strange_operation(
        &self,
        f: impl Fn(add: f32, mul: f32) -> (f32, f32)
    ) -> (f32, f32) {
        f(add: self.x, mul: self.y)
    }
}

let closure = |pub add, other arg| { (add + 42.0, arg * 42.0) };

fn twos(x: f32, y: f32) -> (f32, f32) {
    (x + 2.0, y * 2.0)
}

fn twos(pub x: f32, y: f32) -> (f32, f32) {
    (y + 2.0, x * 2.0) // inverted x & y
}

// Long versions, always valid, exact match for function signature
some_point.strange_operation(|pub add, pub mul| closure(add: add, other: mul))
some_point.strange_operation(|pub add, pub mul| twos(add, mul))
some_point.strange_operation(|pub add, pub mul| twos(x: add, mul))

// No need for exact match though since each closure is unique here
some_point.strange_operation(|add, mul| closure(add: add, other: mul))
some_point.strange_operation(|add, mul| twos(add, mul))
some_point.strange_operation(|add, mul| twos(x: add, mul))

// Disambiguation version
// Those are NOT method calls and the ending ':' is mandatory with this syntax,
// just as '_' is for anonymous arguments
some_point.strange_operation(twos(_:_:))
some_point.strange_operation(twos(x:_:))
some_point.strange_operation(closure(add:other:))
```

Note how the names declared in the `Point::strange_operation`'s `f` closure are not mandatory at the
call site: `some_point.strange_operation(twos(_:_:))` does not expose the names expected but it
still works: this is a feature, which 'casts' argument names when passing a function as closure. It
is here to help with brevity and clarity: while we could require the long form all the time, it
would be heavy and does not add much value since the two versions after are still unambiguous in
terms of the passed function.

#### Disallowed calls

Note that if overloading brings two versions with a different number of parameters, it is still
necessary to be explicit about which function is passed, to ensure clarity for readers:

```rust
fn twos(pub x: f32, pub y: f32) -> (f32, f32) {
    (x + 2.0, y * 2.0)
}

fn twos(pub x: f32) -> (f32, f32) {
    (x + 2.0, x * 2.0)
}

some_point.strange_operation(twos(x:y:)) // OK
some_point.strange_operation(twos) // ERROR, even if unambiguous from the parameter count POV,
                                   // syntax reserved for a function with no arguments at all
```

See [Overloading resolution][overloading-resolution] for details on this behavior.

## Other points

### Using named arguments with `trait`s

Named arguments are fully usable in `trait`s and types implementing those must respect the _public_
facing name of the argument, the private one can be modified in `impl`ementations:

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

Named arguments introduce a limited form a function overloading that is easy to check for both a
human and the compiler and can be applied to profit fully from heavily used function names like
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

You can think of this form of overloading as the function-level equivalent of `Result<T, E>`, where
the simple name of the type `Result` is not enough for disambiguation: you have to provide the
parameters and so `Result<Option<()>, ()>` and `Result<(), ()>` are different types overloading the
same root name. This is an integral part of the Rust type system and is checked at compile time,
just like named arguments.

### Mixing named and unnamed arguments

**Yes** it is possible, without any restrictions (beside the one on `self` in methods):

```rust
// Calling with an unnamed and a named argument.
my_vec.insert(2, at: 3)

// Declaring a function which mixes named and unnamed arguments in some arbitrary order.
fn mix_and_match(pub named: usize, unnamed: usize, public hidden: usize) { /* ... */ }
```

### Reordering named arguments when calling

**No** it is not possible. Just like unnamed arguments and generics, named arguments are also
position-based and cannot be reordered when calling: `register(name:surname:)` cannot be called as
`register(surname:name:)`.

Reordering them at the definition site is an API break, just like reordering unnamed arguments or
generics is an API break already.

### Documenting named arguments

Talking about functions using named argument uses `register(name:surname:)`, not just `register()`.
This allows differentiating overloads clearly and make it easier to remember named arguments are
used for the function. Cases where one argument is public and the other is not are written as
`register(_:surname:)`. Of course, using the shorthand `register()` is fine when clear in context,
just like we use `Result` to talk about `Result<T, E>`, though this form is intended to be only used
when there are no public arguments, to ensure maximal clarity for readers.

`rustdoc` shows the internal name of arguments already when generating documentation for Rust code.
While leaky, this is very useful to understand some parameters and have names to refer to in textual
documentation, like for [`f32::mul_add`][mul-add], and removing it to instead show only named
arguments would be very detrimental to the user experience.

Instead `rustdoc` would now behave as such:

- Insert the keyword `pub` before arguments that are public and declared with `pub`:
  `fn register(pub name: String)`.
- Insert both the public and private name for arguments that use an identifier:
  `fn opposite(&self, centered_on _: Self) -> Self`. This is taken from how Swift
  [does it](https://swiftdoc.org/v5.1/type/bool/).
- Keep the behavior of showing `_` when a pattern was used as the argument (like above).
- Keep hiding `mut` and `ref` like currently done.
- Allow intradoc-links using `[link](register(_:surname:))` to differentiate overloads (writing
  `[link](register)` would refer to a `register` function that takes only unnamed arguments, to
  avoid silently breaking the link if an overload is added).

[mul-add]: https://doc.rust-lang.org/stable/std/primitive.f32.html#method.mul_add
