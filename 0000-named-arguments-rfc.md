
This is my first attempt at an RFC, any feedback is welcome :).

Named arguments have been proposed before, several times, in several forms. This document will list
below some links found on this forum about them or in past RFCs. It will also review what exists in
other programming languages before presenting this RFC's solution.

But first, some goals for this RFC:

- The solution **must** be backward compatible so that it can be backported to Rust Edition 2015,
  2018 and 2021. Even if a backport is not wanted, having it has a goal means this RFC should not
  conflict with features existing in one edition but not in another.
- The solution should improve readability/usability without requiring new keywords or much in the
  way of typing (so that programmers can use them without having to write a line and a half just for
  some non-critical feature).
- Clearly present other options and alternatives (maybe one of them is better and someone will see
  it before a wrong choice is made).
- _Default parameters_ and _variadic parameters_ are **out of scope**. They are orthogonal to named
  arguments and can be considered with or without named arguments.
- _Overloading_ is **in scope**. The named arguments solution proposed will affect function
  resolution.

---

- Feature Name: `named_arguments`
- Start Date: **TO FILL WITH TODAY'S DATE**
- RFC PR: [rust-lang/rfcs#0000](https://github.com/rust-lang/rfcs/pull/0000)
- Rust Issue: [rust-lang/rust#0000](https://github.com/rust-lang/rust/issues/0000)

# Summary

This RFC introduces _named arguments_ for Rust. Named arguments are the ability to call a function ,
method or closure while precising the caller-facing name of the arguments, greatly improving clarity
in many situations. Of course functions where the argument is already clear do not have to use them:
`sin(x: x)` would be ridiculous and redundant. Named arguments as proposed here are **not**
source-breaking: existing functions and methods will continue to work without any change. Named
arguments as proposed here are **opt-in**. Changing the name of `f(a: usize)` to `f(b: usize)` will
**not** be a breaking change, just like it is not today: once again, the goal is not to force them
on developers but to provide another option that has seen huge success in other languages in a way
that fit with Rust.

Named arguments also introduce a limited form a function overloading that is easy to check for both
a human and the compiler and can be applied to profit plainly from heavily used function names like
`new`.

An example in `Python` for clarity:

```python
def open_port(port: int, max_connexions: int, timeout: int):
    print(f"Port: {port}")
    print(f"Max conn: {max_connexions}")
    print(f"Timeout: {timeout}")

# Calling the function with names for the arguments.
open_port(port=12345, max_connexions=10, timeout=60)
```

# Motivation

The main point of this section is that named arguments make for harder to misuse interfaces through
clarity and simplicity of both declaration and usage.

- Named arguments increase readability.

```swift
// Which is the insertion index and which is the element ?
my_vec.insert(2, 3)

// Clearer without asking for much
my_vec.insert(2, at: 3)

// Maybe too much named arguments ?
my_vec.insert(elem: 2, at: 3)
```

- Named arguments are self documenting.

In the example code above it is not easy for a developer to remember which argument does what simply
by looking at the method call, without having to write a little toy example or look at the
documentation for the type (or the trait). Most of the time Rust helps by asking for different types
in its parameters, but that fails when the type _is_ the same. Autocompletion can help by providing
the names and filling them in advance, meaning no more typing for most people, just clearer code.
Code is also read more than it is written, the clearer it is, the less mistakes slip through
reviews.

- Named arguments are simple to **create** compared to the other options.

In all languages that have them, named arguments are simple to create: they do not require a new
type and they do not require a builder pattern (and so another type). This does not means that
builder patterns or new types are useless: I argue that the use cases are simply not the same. Named
arguments should be used to clarify function calls, **not** write functions and methods with 13
parameters, 7 of which are named: a builder would be more useful in this situation.

- Named arguments are simple to **use** compared to the other options.

Calling a builder for the `my_vec.insert` call above is clearly over-engineering and creating a type
for such a simple operation is overkill too. Named arguments are made to fill this spot where the
other solutions are too big for what's intended but clarity is lost without something more than
positional arguments, especially when types do no conflict.

- Named arguments can be combined with other features to increase readability even more.

It is possible to combine builders/new types with named arguments without problems:

```rust
// Hypothetical Rust syntax for named arguments that does not conflict with
// a ConnectionOptions type.
pool.connect("https://a.b.c/endpoint/", with: ConnectionOptions {
    timeout: 200,
    account: "name",
    ..Default::default()
});

// The same with a builder. Note that the builder takes advantage of the
// hypothetical named arguments syntax too.
pool.connect("https://a.b.c/endpoint/", with: ConnectionsOptionsBuilder::new()
    .timeout(seconds: 200)
    .account("name")
    .build()
);
```

- Reality.

[Taken from a previous RFC](https://github.com/rust-lang/rfcs/pull/2964)

Instead of looking at how code could be written in carefully crafted APIs, we should look at how
code is being written in reality. Programmers don't always have time to rack their brains over how
to create the most beautiful API. They want to get things done.

Named arguments allow iterating quickly without sacrificing readability, because they are dead
simple. There's no need to create new types or make up long function names.

As an example: the (amazing) `cargo` tool [would have a use for named arguments][cargo-named-args]:

```rust
// Code in cargo

compile_opts.filter = ops::CompileFilter::new(
    LibRule::Default, // compile the library, so the unit tests can be run filtered
    FilterRule::All, // compile the binaries, so the unit tests in binaries can be run filtered
    FilterRule::All, // compile the tests, so the integration tests can be run filtered
    FilterRule::none(), // specify --examples to unit test binaries filtered
    FilterRule::none(), // specify --benches to unit test benchmarks filtered
); // also, specify --doc to run doc tests filtered
```

VS

```rust
// Possible code with named arguments

compile_opts.filter = ops::CompileFilter::new(
    library: LibRule::Default,
    binaries: FilterRule::All,
    tests: FilterRule::All,
    examples: FilterRule::none(),
    benches: FilterRule::none(),
); // also, specify --doc to run doc tests filtered
```

Note that in the example above, Rust type system cannot help: the last four arguments are all of the
same type.

- Improve soundness and safety.

The documentation for [`Vec::reserve_exact`][vec-reserve-exact] shows clearly the parameter is for
_additional_ capacity. But is it always clear in code ?

```rust
let mut vec = vec![1];
// Is this `additional` or `total` capacity ? The name of the method is quite
// unclear here.
vec.reserve_exact(10);
```

It is the same for [`f64::atan2`][f64-atan2]: is the parameter `x` or `y` when calling
`orig.atan2(angle)` ? Here `rust-analyzer` cannot even help since the internal parameter name is
`other`. The only way to know is documentation.

An argument against named argument is that hints like those provided by Rust-Analyzer are here for
those cases. This is true, but they are not always available. They can be disabled, reviewing a PR
through a web interface does not have them, reading code on GitHub will not show them, maybe your
coworker does not like them, there are many reasons for them not to appear. Named arguments are part
of the code, they always appear when intended to. Just like types, they help by adding another layer
of clarity to code, which helps with soundness and safety, and just like types can be inferred when
writing `let a = b + c`, named arguments as proposed here are not mandatory: forcing `sin(x: x)` is
**not** improving anything.

- Improve coherence in the language.

Named arguments already exists for `struct`s today: `Latitude { x: 42.1, y: 84.2 }`, having named
arguments for functions can be seen as an extension of that capability.

The previous paragraph opens an argument against: `Wrapper(x)` does not have named arguments and it
is quite clear. I would argue this is false: the argument name **is** the name of the type itself.
Wrapper types are here to increase clarity and provide additional guarantees through the type
system, and they do so by being explicit (`NonZeroUsize`, `NonNull` and friends are wrapper types
that make their usage clear through their name for example).

- Allow for a form of function overloading that is clearly visible.

This would allow reusing short function names while adapting them to context or similar
capabilities, as is already possible for types through the use of generics. See the example in the
guide-level explanation for details.

[cargo-named-args]:
  https://github.com/rust-lang/cargo/blob/b842849732f89df8675eb2d933c384d6338e4466/src/bin/cargo/commands/test.rs#L107-L113
[vec-reserve-exact]: https://doc.rust-lang.org/std/vec/struct.Vec.html#method.reserve_exact
[f64-atan2]: https://doc.rust-lang.org/stable/std/primitive.f64.html#method.atan2

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
    pub fn strange_operation(&self, f: impl Fn(add: f32, mul: f32) -> (f32, f32)) -> (f32, f32) {
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
some_point.strange_operation(twos(_:_:))
some_point.strange_operation(twos(x:_:))
some_point.strange_operation(closure(add:other:))
```

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
some_point.strange_operation(twos) // ERROR, even if unambiguous from the parameter count POV
```

In the same way, `some_point.strange_operation(closure)` is also banned for being ambiguous and
potentially dangerous.

See [Overloading resolution][overloading-resolution] for details on this behavior.

## Other points

### Using named arguments with `trait`s

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

Instead `rustdoc` behaves as such:

- Insert the keyword `pub` before arguments that are public and declared with `pub`:
  `fn register(pub name: String)`.
- Insert both the public and private name for arguments that use an identifier:
  `fn opposite(&self, centered_on _: Self) -> Self`. This is taken from how Swift
  [does it](https://swiftdoc.org/v5.1/type/bool/).
- Keep the behavior of showing `_` when a pattern was used as the argument (like above).
- Keep hiding `mut` and `ref` like currently done.
- Allow intradoc-links using `[link](register(_:surname:))` to differentiate overloads (writing
  `[link](register)` would refer to a `register` function that takes only unnamed arguments).

[mul-add]: https://doc.rust-lang.org/stable/std/primitive.f32.html#method.mul_add

# Reference-level explanation

This is the technical portion of the RFC. Explain the design in sufficient detail that:

- Its interaction with other features is clear.
- It is reasonably clear how the feature would be implemented.
- Corner cases are dissected by example.

The section should return to the examples given in the previous section, and explain more fully how
the detailed proposal makes those examples work.

---

Most points have already been presented in the previous section. This one focuses on those that have
not been detailed enough or that are discussed for the first time, to avoid repetition and
conflicting information through mistakes in editing.

## Two (or more) named arguments with the same public name

There are three cases for this situation:

```rust
fn func1(pub name: u32, pub name: u32) { /* ... */ }
fn func2(pub name: u32, name hidden: u32) { /* ... */ }
fn func3(name hidden1: u32, name hidden2: u32) { /* ... */ }
```

- `func1` is clearly impossible because `name` would have two different meaning inside the
  function's definition. Aside from already being an error in today's Rust, it is simply impossible
  to do for any language that uses names and not position to refer to parameters.

- `func2` and `func3` could work in theory: named arguments as proposed in this RFC are
  position-based and their internal names are different: just like two arguments can have the same
  type without ambiguity, those functions could be allowed.

But named arguments are a feature designed to improve clarity at the call site and calling
`register(name: param, name: param2)` is just as unclear (and arguably worse) than
`register(param, param2)` so this RFC argues for all those forms to either produce an unconditional
error (`func1`) or to produce an error-by-default lint (`func2` and `func3`).

The error-by-default lint is here because it is theoretically possible for very specific cases to
need the same public name twice, but the Swift community has not found such use cases despite their
heavy use of named arguments. Python does not allow this situation to occur at all.

## Overloading resolution

There is one case that was not mentioned in [Calling a function with named arguments
indirectly][calling-a-function-with-named arguments-indirectly]:

```rust
pub struct Point { x: f32, y: f32 }

impl Point {
    pub fn strange_operation(&self, f: impl Fn(add: f32, mul: f32) -> (f32, f32)) -> (f32, f32) {
        f(add: self.x, mul: self.y)
    }
}

fn twos(x: f32, y: f32) -> (f32, f32) {
    (x + 2.0, y * 2.0)
}

fn twos(pub x: f32, y: f32) -> (f32, f32) {
    (y + 2.0, x * 2.0) // inverted x & y
}

some_point.strange_operation(twos) // unambiguously refers to `twos(_:_:)`
```

This special case is necessary to stay compatible with today's Rust and allow named arguments in all
editions (which allows us to introduce them in the standard library).

Passing methods and closures with named arguments is not possible in this shorthand form, to ensure
the following case always behave correctly:

```rust
// Before change

pub struct Point { x: f32, y: f32 }

impl Point {
    pub fn strange_operation(&self, f: impl Fn(add: f32, mul: f32) -> (f32, f32)) -> (f32, f32) {
        f(add: self.x, mul: self.y)
    }
}

fn twos(pub x: f32, y: f32) -> (f32, f32) {
    (y + 2.0, x * 2.0) // inverted x & y
}

some_point.strange_operation(twos) // Previously referred to `twos(x:y:)`,
                                   // now unambiguously and silently refers to `twos(_:_:)`

// Added in a new commit

fn twos(x: f32, y: f32) -> (f32, f32) {
    (x + 2.0, y * 2.0)
}
```

The compiler would enforce writing `some_point.strange_operation(twos(x:y:))` to ensure this silent
overload would not happen.

## Calling a function with named arguments indirectly, the case of `self`.

```rust
pub struct Point { x: f32, y: f32 }

impl Point {
    pub fn strange_operation(&self, f: impl Fn(add: f32, mul: f32) -> (f32, f32)) -> (f32, f32) {
        f(add: self.x, mul: self.y)
    }
}
```

The full reference to `Point::strange_operation` is `Point::strange_operation(_:_:)`, with **two**
unnamed arguments, not one. Writing `my_point.strange_operation(_:)` is incorrect, just like trying
to pass `my_point.strange_operation` is invalid already.

## Interaction with traits

Parameter names are not part of a trait API in today's Rust, justly so: they are helpful guide when
looking at documentation but are not part of the public API when calling the method.

This RFC makes the _public_ part of a named argument an API requirement when implementing the trait.

This requirement can be fulfilled in two ways and fail in one, as demonstrated by the following:

```rust
trait MyTrait {
    fn func(pub name: u32, name2 hidden: u32);
}

struct ExactSame;
struct OnlyPubliclyTheSame;
struct WrongImpl;

impl MyTrait for ExactSame {
    // Both public and internal names are the same as the trait's declaration.
    fn func(pub name: u32, name2 hidden: u32) { /* ... */ }
}

impl MyTrait for OnlyPubliclyTheSame {
    // The public names are the same but their internal name is different, this is allowed.
    fn func(name hidden1: u32, pub name2: u32) { /* ... */ }
}

impl MyTrait for WrongImpl {
    // The public names are different, this is an API break and is forbidden.
    fn func(pub name0: u32, name1 hidden: u32) { /* ... */ }
}
```

Traits are one of Rust most powerful feature and this RFC endeavours to integrate well with them, to
avoid making them second class citizens.

One special case that comes to mind is closure and the `Fn` family of traits ([with an example from
the Nomicon][nomicon-example]):

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

This `impl` is valid for **all** closures matching the expected types and arity thanks to implicit
casting away of names in closures. Said another way, it is not possible to restrict an `Fn`
implementation based on named arguments alone: the syntax is valid but casting will ensure it has no
effect. As such, implementations can conflict if their only difference is named argument.

To ensure future compatibilities, using named arguments in such a position would be banned (either a
hard error or an error-by-default lint), so that if we ever specialize based on this, existing code
is not suddenly broken.

[nomicon-example]: https://doc.rust-lang.org/nomicon/hrtb.html

## Interaction with type ascription

> Citation from a past RFC:
>
> Using `=` would be ambiguous, as `foo = bar` is a valid expression (returning `()`). Using `:` as
> the RFC suggests would be unambiguous today, but become ambiguous in the future if we ever get
> type ascription (the ability to say let `foo = bar(): int;`, which uses a colon to specify the
> type of an expression), which is something that has been wanted for a long time. An alternative
> that is unambiguous even with type ascription would be `=>`.

While this seems to kill any hope of using `:`, there is missing information here.

First, `:` fits more nicely with how functions parameters are declared today. `=` is forbidden for
the reason given in the quote above. `=>` is available but reminds of pattern matching when it is
absolutely not. A function called as `matches(name => param)` would be an easy source of confusion.

Second, `:` as type ascription and `:` as a delimiter for named arguments do not, in fact, conflict.
The first _always_ has the form `expr : type`, the second `expected_identifier : expr`.

What's more, there is talk about [disallowing type ascription in some places][disallow-asc] by the
lang team.

[disallow-asc]:
  https://rust-lang.zulipchat.com/#narrow/stream/269230-t-lang.2Ftype-ascription/topic/how.20to.20disallow.20ascription

## Interaction with function pointers

In today's Rust, this is perfectly valid, even when using all Clippy warnings:

```rust
fn example1(a: u32) -> u32 { a }
fn example2(b: u32) -> u32 { b }

// No public name
let _: fn(u32) -> u32 = example1;
let _: fn(u32) -> u32 = example2;

// Mark a public name as 'a' and the function used 'a' in declaration.
let _: fn(a: u32) -> u32 = example1;

// Mark a public name as 'c' but used 'b' in declaration
let _: fn(c: u32) -> u32 = example2;
```

This RFC does **not** modify this behavior. Function pointers are often used in FFI and this
behavior is important for it, requiring concordance of named arguments when they do not exist in C
would be harmful.

This raises the problem of overload, which can happen in several forms.

The first one is easily fixed by adding a type hint (though that is **not** the proposed solution):

```rust
fn new() -> u32 { 42 }
fn new(using number: u32) -> u32 { number + 42 }

let _ = new;
//  ^ ERROR: cannot determine which `new` function is intended, use a type hint:
//  `: fn() -> u32` or `: fn(u32) -> u32`.
```

The second one is more complicated:

```rust
fn new(adding number: u32) -> u32 { 42 + number }
fn new(removing number: u32) -> u32 { 42 - number }

let _ = new;
```

Using a type hint in the example above would not work. The solution of asking for the argument name
in the type hint cannot work because the syntax `let _: fn(c: u32) -> u32 = example2;` is already
valid today and has no meaning aside from documentation for human. Notably, it is used in FFI with C
to document parameters expected by callbacks and changing this would be a potentially huge breaking
change.

Instead, the proposed solution adds a new syntax:

```rust
fn new(adding number: u32) -> u32 { 42 + number }
fn new(removing number: u32) -> u32 { 42 - number }

let _ = new(adding:);
```

This would not be a function call (made clear by the `:` at the end of the parameter list). In case
of several arguments, it would be used as `new(adding:and:)`.

This would not raise a problem with type ascription because there would be no type after the `:`s,
especially after the last one and so the compiler would be able to unambiguously decide what is
happening.

It would be even easier in the case of a function call: `ffi_call(object, new(adding:))` because the
compiler would know what to expect as a type for the second parameter of `ffi_call` here.

## About `_`

It is possible to write `fn foo(_: i32) {}` today, and it is often used when implementing traits.

This RFC bans `fn foo(pub _: i32) {}` and `fn foo(_ name: i32) {}` (and so `fn foo(_ _: i32) {}`)
because it would create an ambiguity with `fn foo(_: i32) {}` with can be named as `foo(_:)` and
because named arguments are supposed to increase readability: `foo(_: 42)` is **not** improving
anything about it.

`fn foo(name _: i32) {}` is of course still available and not banned at all by this RFC: it is using
`_` as the public name which is banned.

## Interaction with `#[no_mangle]`, `extern "C"` (or anything but the unstable Rust ABI)

Such functions are forbidden from using named arguments _if_ they are overloaded based on them. If
they are not, the function can be uniquely identified by just its name even for FFI, which is the
point of this attribute. Such functions would still be a warn-by-default lint because having
different calling styles for FFI and Rust seems like a Bad Idea(TM) in most cases.

This allows Rust code to call such function using named arguments while C code will not have to use
them, and thus makes the following example valid:

```rust
#[no_mangle]
extern "C" fn callback(pub return_code: u32) { /* ... */ }

// lib.rs
callback(return_code: 42);

// main.c
callback(42);
```

This one on the other hand, would not compile:

```rust
#[no_mangle]
extern "C" fn callback(pub return_code: u32) { /* ... */ }

#[no_mangle]
extern "C" fn callback(pub data: *const ()) { /* ... */ }
```

# Drawbacks

Why should we _not_ do this?

## Overloading

Historically (and not limited to Rust), overloading has been seen as a mixed bag: it allows lots of
expressiveness but can quickly become unclear: which type is passed ? Which overload is called ? Is
that constructor the move or copy one ?

This has mostly not been a problem for Swift and Python, because their use of overloading is based
on something more visible, named arguments, not types invisible without hints. This is the form
proposed for Rust and as such, it will not fall prey to the lack of clarity that simple
type/number-based overload is subject to.

# Rationale and alternatives

- Why is this design the best in the space of possible designs?
- What other designs have been considered and what is the rationale for not choosing them?
- What is the impact of not doing this?

## Rationale

There have been several choices made in this RFC that need justification. In no particular order:

- Using `:` (see alternatives)
- Using `pub` only sometimes
- Clunkiness of `pub`
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
then catch the wrong cases, though there are probably situations where that wouldn't work.

The non-source-preserving solution is for the compiler to propose fixes such as `Option::or(_:_:)`
or to introduce unambiguous closures itself: `|a0, a1| a0.or(a1)`.

As the main purpose of named arguments is clarity, the preferred solution would to ask for
clarification when the situation is ambiguous. This has the huge disadvantage of gating named
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

`pub` is not asked for when the two bindings are different because the situation makes it clear
already: two identifiers cannot be placed that way next to each other without an operator or a comma
anywhere else in normal Rust (it can happen in macros though). Therefore the only possible case is
that one name is public and the other is private. Using the first as the public name is then
logical: it is in the position of the `pub` keyword, taking advantage of the similar placement with
a similar functionality, which is important for consistency.

## Alternatives

### Using `:` instead of `=`, `:=`, `=>`, ...

#### Especially `=`

Several macros in the Rust Standard Library have had a form of named arguments for a while:

```rust
println!("The answer is {x}{y}", x = 4, y = 2);
```

The problem is that they use `=`, not `:`, unlike this RFC. Despite that, I think it is important to
keep `:` because `=` remind of an assignment and named arguments are **not** assigning to anything.

#### Others

- `:=` cannot be used backward compatibly because macros could be using it already and changing how
  it is parsed would break those. I have not done a survey about this so I have no numbers to
  present. In the spirit of fairness, breaking how some macros are parsed has been done in the past
  when it was determined very few used the pattern (usually via a crater run).

- `=>` looks way too much like pattern matching when it is not.

- `->` is used for return types, seems like a bad idea to give a completely different meaning.

### Using `as`

Using `as` instead of `pub` can be found as an off-hand idea on Reddit and forums about named
arguments and Rust, but it presents some defaults that are not there with `pub`. But first, here is
how it would be used:

```rust
fn test(bar as baz: usize) { /* use baz here */ }

// Use bar here
test(bar: 42)
```

This form is limiting on some points: it is wasteful to have the same public and internal names:
`data as data`, can easily be mistaken for a type cast and it almost entirely precludes introducing
context-aware keywords in the future which would make functions like
`fn EncodedString::new(data: String, as encoding: Encoding) -> EncodedString` possible.

### Using an alternative sigil like `.`, `@`, ... because `pub` is clunky

Lots of alternative forms have been proposed for named arguments, either as full blown (pre-)RFCs or
as quick bike-shedding when discussing those. Most bike-shed options will be ignored since they
either ignore the declaration or call point, which is not possible in a serious attempt at named
arguments. I will miss others because this section would be longer than the rest of the RFC if I did
not.

- `'name`: re-use the lifetime sigil. Lifetimes are already difficult enough (and conflict with
  labels) without adding a third meaning to `'`.

- Using one of `@$^#.` at both declaration and call point:

```
foo(@c = 5, @b = 3, @a = 1);
foo($c = 5, $b = 3, $a = 1);
foo(^c = 5, ^b = 3, ^a = 1);
foo(#c = 5, #b = 3, #a = 1);
foo(.c = 5, .b = 3, .a = 1);
```

I find all of those **very** clunky at the call point. Functions are often made to be called several
times and having to wade through a sludge of ultimately unneeded symbols to understand calls seems
like a Bad Idea (TM). It could be okay at the declaration point though, but the lack of symmetry
could maybe hurt since it was not a keyword but a sigil ?

[As said by Tom-Phinney](https://internals.rust-lang.org/t/pre-rfc-named-arguments/12730/19), `.`
has an advantage though:

> I like the leading point (`.`) because, for me, it implies that the following parameter name is
> interpreted with respect to the called function name. It's clearly not method syntax, but for me
> it does have a somewhat-similar mental model of name scope.

I find that advantage quickly negated on multi-lines call though:

```rust
some_long_function(
    unnamed_very_long_struct_decl { ... }, // < oups there was a comma here
    .arg = (42, 44),
    //   ^ maybe too easy to miss when skimming and think of a function call
)
```

In this situation, the dot `.` is a hindrance. What's more, it adds clutter at the call site, which
is a big no-no for this RFC.

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

### Use an attribute

```rust
#[with_named_arg] // or something else
fn foo(a: i32) -> i32 { a * 2 + 4 }

let b = foo(a: 42);
```

While this is very readable at the call site, it is somewhat heavy at the declaration point, does
not allow mixing named and unnamed arguments (it could with something like `#[with_named_arg(a)]`,
even heavier) and it adds even more bike-shedding: what do we call this attribute ? What if the
perfect name is already taken by a macro from another crate ? It also either remove the opportunity
to have different public and internal names or adds a lot of sigil :
`#[with_named_arg(public_name = long_internal_name)]`, and probably doesn't compose well with
patterns.

### Do nothing

Without named arguments Rust is already a very good language. Named arguments are a nice feature and
can help with safety and soundness but they are not the greatest thing since sliced bread either and
Rust can live without them, as it already has for years.

This has been rejected for several reasons in this RFC, reasons that have been explained earlier
(safety, soundness, increased readability outside of IDEs with type hints) but also because the
alternatives are either insufficient or too heavy-handed. Named arguments have also been on the
"nice-to-have-but-needs-design" list for years. This RFC is just the latest attempt at the "design"
part.

# Prior art

Discuss prior art, both the good and the bad, in relation to this proposal. A few examples of what
this can include are:

- For language, library, cargo, tools, and compiler proposals: Does this feature exist in other
  programming languages and what experience have their community had?
- For community proposals: Is this done by some other community and what were their experiences with
  it?
- For other teams: What lessons can we learn from what other communities have done here?
- Papers: Are there any published papers or great posts that discuss this? If you have some relevant
  papers to refer to, this can serve as a more detailed theoretical background.

This section is intended to encourage you as an author to think about the lessons from other
languages, provide readers of your RFC with a fuller picture. If there is no prior art, that is
fine - your ideas are interesting to us whether they are brand new or if it is an adaptation from
other languages.

Note that while precedent set by other languages is some motivation, it does not on its own motivate
an RFC. Please also take into consideration that Rust sometimes intentionally diverges from common
language features.

## Past Rust-only considerations

This subsection focuses on the discussion that happened in the Rust world about named arguments.

> DISCLAIMER: I did not read _everything_ in details, it is possible I missed things. I at least
> skimmed quickly over all of those listed below.

### Relevant discussions

Here are some past discussions on IRLO and past RFCs:

1. The [Wishlist issue](https://github.com/rust-lang/rfcs/issues/323) says named arguments (and
   other features) are thought about but the design space must be studied before rushing into one
   solution that will later prove insufficient or even plain wrong. Even if this RFC is not approved
   I hope the section below about other programming languages listing the different possibilities
   chosen by others will help future RFCs that will attempt to tackle this or something similar.
1. The (I think) [first RFC to propose them](https://github.com/rust-lang/rfcs/pull/257) introduced
   them in conjunction with _default parameters_ and was closed as postponed. Some remarks on this
   RFC raised good points that have also been raised in subsequent RFCs, they will be listed in a
   section below.
1. [Struct sugar RFC #343](https://github.com/rust-lang/rfcs/pull/343): it proposed both a form of
   named arguments and default parameters. It was marked as postponed and lots of people commenting
   on the issue wanted less magical sugar.
1. [Keyword arguments #805](https://github.com/rust-lang/rfcs/pull/805)
1. [Named arguments #2964](https://github.com/rust-lang/rfcs/pull/2964)
1. [Pre-RFC thread for #2964](https://internals.rust-lang.org/t/pre-rfc-named-arguments/12730/):
   there was much love for `.public_name` + `=` in this thread. Those were not chosen here for
   reasons explained in [Rationale and Alternatives][rationale-and-alternatives]. This thread and
   several before also raised concerns about the clunkiness of `pub`, again argued about in the
   previous section.

### Recurring points

Some arguments and opinions are recurring in most of the links above. I will try to list and
summarise most of them here. They are in no particular order.

- **Named arguments make changing function parameters names a breaking change**: this is certainly
  true. That's even the point of named arguments, to have a stable and clear interface to a function
  call, just like some `struct`s have public members or like `enum A { Variant { line: String } }`
  instead of simply `enum B { Variant(String) }`. This point is often raised to argue about brittle
  syntax. This can be true if the feature is wrongly thought out and designed and named arguments
  should certainly make it clear what is named and what is not so that programmers can be sure they
  are not breaking the public interface of some function in a minor version change. **But** this
  argument is also false. Named arguments as proposed here **do not break existing Rust code** one
  bit, because the public name is separate from the internal binding. If both were always shared,
  then yes the feature would be error-prone, but they are not, for exactly this reason.

- **Named arguments encourage less well thought out interfaces**: I do not think any conclusive
  evidence has ever been brought to light about this point. On the other hand, the opposite has been
  extensively studied and battle-tested through Swift's version of the feature, which is lauded by
  practitioners of the language, notably library designers. Another example, from Rust even, is
  structs. Why is `Latitude { x: 42.1, y: 84.2 }` (instead of `Latitude { 42.1, 84.2 }`) seen as
  good if named arguments are not good ? To go further, why even name types ? We only need to know
  the type layout after all, and then we can access all of its data through offsets and
  dereferencing (such a language does exist, it's called Assembly).

- **Use a (builder) type instead**: this argument is counterproductive to me, here it is in another
  form: why would you use (especially generic) functions when macros can do the job and more well
  enough ? Types (and builders) have their uses and they can be used in conjunction to named
  arguments, they are not opposites, just like macros and functions nowadays.

- **Suppose named arguments are allowed, soon people will ask for arbitrary argument order and
  optional arguments**: they are different features. One being accepted is **not** a sign of the
  other being accepted. An example is inheritance in today's Rust. Traits can be subtraits
  (`DoubleEndedIterator: Iterator`) but types cannot inherit other types and this has never been
  accepted before when people asked for it.

- **We would benefit far more from reducing the boilerplate involved in the builder pattern**: the
  builder pattern is not opposite to named arguments. Named arguments will **not** help you when
  there are 13 parameters to handle for a function input. A builder pattern will be overkill if
  there are only two `usize` parameters.

- **Developers need to memorize what arguments are positional and cannot be named in function calls,
  and what arguments are named**: this is true. The response is that code is read **far** more than
  it is written. When a choice has to be made between the writer and reader this should be taken
  into account. Named arguments incur a cost of a minute or two of thinking at most in the majority
  of cases from my experience in Python 3 and Swift. They can save dozens of peoples hours of
  debugging and reading documentation. In today's Rust you need to remember the name of a struct's
  field to initialize it but I have not seen people complain about it either, despite the fact that
  there is no difference between the private and public name of the field. What's more,
  autocompletion exists and is used by a lot of people. It is quite simple to autocomplete a
  function call with named arguments: instead of writing `myfunction(<cursor>)`, write
  `my_function(at: <cursor>)`.

### Named arguments already exist in Rust

This is minor but consider the following:

```rust
trait Restriction {
    type Inner;
}

trait Database: Restriction<Inner = u32> {}
                         // ^^^^^ This is a type-level named argument

fn one_string_to_bind_them_all<I: Iter<Item = String>>(i: I) -> String { /* ... */ }
                                    // ^^^^ This is another
```

### Overloading already exists in Rust

Overloading is already available, from a certain point of view, in today's Rust, with two main ways
to achieve it.

The first is with members and methods:

```rust
struct Sizes { data: Vec<usize> }

impl Sizes {
    fn data(&self) -> &Vec<usize> { &self.data }
}

let data_1:  Vec<usize> = some_sizes_1.data;
let data_2: &Vec<usize> = some_sizes_2.data();
```

The second is with modules (and crates, since they behave as modules for this):

```rust
mod a { pub fn data() -> usize { 42 } }

mod b { pub fn data() -> &'static str { "42" } }

let from_a: usize        = a::data();
let from_b: &'static str = b::data();
```

This one can even be argued as reverse form of named arguments: the function name is the same and a
marker (here the module's name) is used to differentiate.

There is a third one that is nightly-only for now (taken from [this blog post](nightly-overload)):

```rust
// required to implement a function with `extern "rust-call"`
#![feature(unboxed_closures)]
#![feature(fn_traits)]

struct Multiply;

#[allow(non_upper_case_globals)]
const multiply: Multiply = Multiply;

impl FnOnce<(u32, u32)> for Multiply {
    type Output = u32;
    extern "rust-call" fn call_once(self, a: (u32, u32)) -> Self::Output {
        a.0 * a.1
    }
}

impl FnOnce<(u32, u32, u32)> for Multiply {
    type Output = u32;
    extern "rust-call" fn call_once(self, a: (u32, u32, u32)) -> Self::Output {
        a.0 * a.1 * a.2
    }
}

impl FnOnce<(&str, usize)> for Multiply {
    type Output = String;
    extern "rust-call" fn call_once(self, a: (&str, usize)) -> Self::Output {
        a.0.repeat(a.1)
    }
}

fn main() {
    assert_eq!(multiply(2, 3), 6);
    assert_eq!(multiply(2, 3, 4), 24);
    assert_eq!(multiply("hello ", 3), "hello hello hello ");
}
```

[nightly-overload]:
  https://lazy.codes/posts/awesome-unstable-rust-features/#fn-traits-and-unboxed-closures

## What about other programming languages ?

Rust does not exist in a vacuum and a lot of people have thought about named arguments for their
preferred language. This section will look at what other languages have done and how (and if) they
solved the problems that named arguments attempts to solve.

Since many languages have them in some form or other this will be more of a list presenting the
different options with a summary at the end, not a list of functionalities per language.

Note that languages may appear in several categories: they are not exclusive. All languages ever
created are not listed and it is entirely possible a solution (and the language using it) was
missed. If you find that is the case, please signal it to help improve this section.

Languages that have direct support for named arguments will not be listed in the other categories,
even if they fit in them.

Source: [Rosetta code]

[rosetta code]: https://rosettacode.org/wiki/Named_parameters

### Named arguments through comments

Some examples found in LLVM code ([ex1], [ex2], [ex3]):

```c++
config::Provider::fromYAMLFile(UserConfig, /*Directory=*/"", TFS)

/* Override */ OverrideClangTidyOptions, TFS.view(/*CWD=*/llvm::None)

llvm::sys::fs::real_path(CheckFile, Path, /*expand_tilde=*/true)
```

All languages that support inline comments can do this. The simple fact this is used at all is
telling since it is very easy for such comments to get out of date and become obsolete or even plain
wrong but using such a brittle form of named arguments was still deemed necessary and worth the
maintenance cost.

All languages that support comments but not inline comments can do this if the developer writes the
function call on several lines. The above examples could have been written that way:

```c++
config::Provider::fromYAMLFile(
    UserConfig,
    "", // Directory
    TFS
)

// Taking even more space:
llvm::sys::fs::real_path(
    CheckFile,
    Path,
    // expand_tilde
    true
)
```

I do not know of a single programming language that does not support the second form, even COBOL can
do it.

[ex1]:
  https://github.com/llvm/llvm-project/blob/c6a384df1f8ab85815160297543ab329e02560ef/clang-tools-extra/clangd/tool/ClangdMain.cpp#L794
[ex2]:
  https://github.com/llvm/llvm-project/blob/c6a384df1f8ab85815160297543ab329e02560ef/clang-tools-extra/clangd/tool/ClangdMain.cpp#L818
[ex3]:
  https://github.com/llvm/llvm-project/blob/c6a384df1f8ab85815160297543ab329e02560ef/clang-tools-extra/clangd/tool/ClangdMain.cpp#L849

### Named arguments through direct types

This section is for languages that do not have named arguments directly but can use external types
to emulate them. Pretty much all languages can do that so this section is only for languages that do
**not** have named arguments directly.

An example in `C`:

```c
#include <stdio.h>

struct OpenPortOptions {
    unsigned int port;
    unsigned int max_connexions;
};

void open_port(const struct OpenPortOptions options) {
    printf("port: %d\n", options->port);
    printf("max connexions: %d\n", options->max_connexions);
}

// Call with:
int main(void) {
    // Short version, needs a cast, cannot be reused, avoids declaring a local variable.
    open_port((struct OpenPortOptions){ .port = 12345, .max_connexions = 10 });

    // Long version, can be reused if necessary.
    const struct OpenPortOptions options = { .port = 12345, .max_connexions = 10 };
    open_port(options);
    // It is possible to invert the order of the members.
    const struct OpenPortOptions options_2 = { .max_connexions = 10, .port = 54321 };
    open_port(options_2);
    return 0;
}
```

In such languages an external type is often necessary to implement named arguments. If you have
functions taking another set of arguments, you will need another type. Depending on the language,
types can be created inline (`call(MyType { name1: val1, ... })`, as in Rust) or not, which adds
more boilerplate (as in the long form of the C example above). Most statically typed languages needs
the type to be explicit too, adding more boilerplate.

In some languages, like JavaScript, creating an external type is not necessary, passing an anonymous
type with the expected properties is enough. This reduces the boilerplate, at the cost of clarity:
expected properties must be documented, often without the help of the language to check for their
existence before the function is called.

While this solution works when it is only needed for a few specific functions, it does not scale
well, especially if the concerned functions are public: the helper types will have to be too,
widening API surface and adding boilerplate for every user of the library, not just the author.

#### Languages using this method

- ALGOL 68 (not known to be used in any real code though)
- Bracmat
- C
- C++
- Forth
- Go
- Haskell
- JavaScript
- jq
- Lingo
- Perl
- PHP
- Rust
- StandardML
- Tcl
- Wren

### Named arguments through builder types

Some languages cannot use the previous method and must use a _Builder pattern_ to get a form of
named arguments, as in the (shortened) Java example below. As with the last method, pretty much
every language can use this method. The list below will only consider languages that cannot apply
the previous (shorter) method nor have named arguments.

```java
processNutritionFacts(new NutritionFacts.Builder(240, 8)
                                        // What are the units used below ?
                                        // The builder is only partially
                                        // helpful here.
                                        .calories(100)
                                        .sodium(35)
                                        .carbohydrate(27)
                                        .build());
```

This is often boiler plate-heavy (a builder type and an option type are needed) and just transmit
part of the problem to the builder type itself (as in the `Builder(240, 8)` call above).

It also often easier to forget to make some call if the builder type is not a state machine but a
simple storage for optional values. On the contrary having a state machine can force certain calls
even when they are not used by the method using the result of the `.build()` call.

Builder types are very appropriate for more complex configurations but will quickly become heavy
boilerplate for two-parameter methods. What's more, builder pattern are often not used internally,
only in public facing APIs. Private functions and methods should not be left on the side just
because they are private, but they should also not incur heavy maintenance costs of boilerplate just
because the developer wanted to write something safe and self-documenting.

#### Languages using this method

- Java
- C# (before 4.0)

### Optional and/or unordered named arguments

This section is for languages that have named arguments but function calls can choose whether to use
them or not.

An example in Python 3:

```python3
def open_port(port, max_connexions):
    print(f"port: {port}")
    print(f"max connexions: {max_connexions}")

open_port(12345, 10)
open_port(12345, max_connexions=10)
open_port(max_connexions=10, port=12345)

# This line will produce an error but this is not the case for all languages
# open_port(port=12345, 10)
#
# SyntaxError: positional argument follows keyword argument
```

When languages have this feature, using named arguments is left to the user, not the author of a
library but it is library authors that are responsible for the names and changing them is a
source-breaking change.

This places additional burden on library authors without offering them much: since users can just
ignore the names authors are not able to rely on them to help with clarity and must instead often
design around them.

What's more, order is often not important as long as the names match which means a reviewer has to
be careful when two parameters are named similarly: there could be an uncaught bug hiding.

> From what I could find some domains force the use of named arguments when they are available, like
> Ada in military programs though I did not find conclusive proof one way or the other.

#### Languages with this feature

- Ada
- C# (since 4.0)
- Common Lisp
- Dyalect
- Elixir
- Factor
- Fortran
- Julia (needs a `;` in a function parameter list, the names after are mandatory when calling)
- Kotlin
- Lasso (only unordered, not optional)
- Lua
- Maple
- Modula-3
- Nermerle
- Nim
- Oz
- Phix (named arguments must occur to the right of unnamed arguments but order does not matter)
- Php 8
- PowerShell
- Python (2 & 3)
- R (will fill missing named arguments with unnamed arguments in the given order, very brittle)
- Racket
- Raku (seems to be the same behaviour as R)
- Ruby
- Scala
- Sidef
- Standard ML
- Suneido (same as Phix)
- Visual Basic

### Mandatory and ordered named arguments

This section is for languages that have the strictest form of named arguments: mandatory and
ordered.

```swift
func open_port(_ port: Int, withMaxConnexions max_connexion: Int) {
    print("\(port)")
    print("\(max_connexion)")
}

open_port(12345, withMaxConnexions: 10)
```

Depending on the language there is a public name for the argument or not. When this is not the case
named arguments are often seen as a burden because having to call `sin(x: x)` is redundant and
brings nothing in term of informations while still pushing the burden of increased API surface on
maintainers.

On the other hand, users of languages with named arguments that have both a public name and a
private name (AppleScript, Objective-C, OCaml, Swift) often seem to miss them in other languages for
both their clarity and convenience. The ability to turn them off is a must though, as seen in the
`sin(x: x)` example.

#### Languages using this feature

- AppleScript
- Objective-C
- OCaml
- Python
- Swift

### More on Python 3 and Swift

Python 3 and Swift are special and very informative examples because they are two languages where it
was possible to write named arguments only functions but the languages moved in opposite directions:
Python 3 gained a way to remove them in [PEP 570] while Swift continues to use them more and more
and functions in Swift are documented with the name of their arguments:
`open_port(_:withMaxConnexions:)`.

> Note: while this section concentrate on Swift, it must be noted that OCaml provides the same
> features using a different approach. See [this link][ocaml-rosetta] for more informations and an
> example. The example of Swift has been chosen because it is more widely used than OCaml and closer
> the C-family of languages, ensuring its syntax will be understood even by non-practitioners, and
> especially the Rust community that is the target of this document. The same goes for Objective-C
> and AppleScript.

[ocaml-rosetta]: https://rosettacode.org/wiki/Named_parameters#OCaml
[pep 570]: https://www.python.org/dev/peps/pep-0570/

#### Python 3

Python 3 has had named arguments for a long time, since it was first released. Despite that they are
not used much outside of necessity to bypass default arguments and change the nth argument when
`n-1` has a default value. Many Python 3 functions and methods that are implemented in C behind the
scene even forbid named arguments, `range` being one of the most famous example.

```python
def only_named_arguments(*, arg1: int, arg2: str):
    print(arg1)
    print(arg2)

# Using both names (in whatever order) is the only valid way to call the function
only_named_arguments(arg2="two", arg1=1)
```

With [PEP 570], Python 3 introduced a way to disable named arguments for a function/method call:

```python
def only_positional_arguments(arg1: int, arg2: str, /):
    print(arg1)
    print(arg2)

# Using positional arguments is the only valid way to call the function
only_positional_arguments(1, "two")
```

#### Swift

Swift has had named arguments since its inception and they are fully integrated to the language.
They affect overload resolution for example so methods are described as `Int.isMultiple(of:)`, not
`Int.isMultiple`.

Swift named arguments are opt-out instead of opt-in. This was possible because they were here from
the start, which is obviously not a possibility for Rust.

Below are all the possible ways for Swift named arguments to work in the language:

```swift
// - `range` is both the public and internal name, it must be used when calling
//   the function and when writing its implementation.
func random(range: Range<Int>) -> Int {
    var g = SystemRandomNumberGenerator()
    return Int.random(in: range, using: &g)
}

// - `in` is the public facing name, usable only when calling the function.
// - `range` is the internal name, usable only inside the function.
func random(in range: Range<Int>) -> Int {
    var g = SystemRandomNumberGenerator()
    return Int.random(in: range, using: &g)
}

// - `_` is a placeholder used to note the function is called without a named
//   argument. `range` CANNOT be used when calling the function.
// - `range` is the internal name, usable only inside the function.
func random(_ range: Range<Int>) -> Int {
    var g = SystemRandomNumberGenerator()
    return Int.random(in: range, using: &g)
}
```

# Unresolved questions

- What parts of the design do you expect to resolve through the RFC process before this gets merged?
- What parts of the design do you expect to resolve through the implementation of this feature
  before stabilization?
- What related issues do you consider out of scope for this RFC that could be addressed in the
  future independently of the solution that comes out of this RFC?

## Defaults parameters

Default parameters and named arguments are often cited together but in reality they are quite
orthogonal features. They compose well together in several languages but that does not means they
are inseparable from a design point of view.

Whether they should be added to Rust or not should be considered in another RFC.

## Allowing keywords

See [Allow Keywords][allow-keywords] in Future Possibilities.

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

