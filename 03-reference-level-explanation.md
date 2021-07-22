# Reference-level explanation

[reference-level-explanation]: #reference-level-explanation

This is the technical portion of the RFC. Explain the design in sufficient detail that:

- Its interaction with other features is clear.
- It is reasonably clear how the feature would be implemented.
- Corner cases are dissected by example.

The section should return to the examples given in the previous section, and explain more fully how
the detailed proposal makes those examples work.

## Why use `pub` and not just write the identifier twice ?

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

## Two (or more) named arguments with the same public name

There are three cases for this situation:

```rust
fn func1(pub name: u32, pub name: u32) { /* ... */ }
fn func2(pub name: u32, name hidden: u32) { /* ... */ }
fn func3(name hidden1: u32, name hidden2: u32) { /* ... */ }
```

- `func1` is clearly impossible because `name` would have two different meaning inside the
  function's definition. Aside from already being an error in today's Rust, it is simply impossible
  to do.

- `func2` and `func3` could work in theory: named arguments as proposed in this RFC are
  position-based and their internal names are different: just like two arguments can have the same
  type without ambiguity, those functions could be allowed.

But named arguments are a feature designed to improve clarity at the call site and calling
`register(name: param, name: param2)` is just as unclear (and arguably worse) than
`register(param, param2)` so this RFC argues for all those forms to either produce an unconditional
error (`func1`) or to produce an error-by-default lint (`func2` and `func3`).

The error-by-default lint is here because it is theoretically possible for very specific cases to
need the same public name twice, but the Swift community has not found such use cases despite their
heavy use of named arguments.

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

Traits are one of Rust most powerful feature and this RFC endavours to integrate well with them, to
avoid making them second class citizen.

## Interaction with destructuring

```rust
fn process_pair((id, name): (u32, String)) { /* ... */ }
fn process_point(Point { x, y: renamed }: Point) { /* ... */ }
```

Those declarations are valid in today's Rust but how do we add named arguments to them ? Does the
`pub` keyword as used in previous examples make any sense here ?

The proposed solution is the following:

```rust
fn process_pair(public_name (id, name): (u32, String) ) { /* ... */ }
fn process_point(public_name Point { x, y: renamed }: Point) { /* ... */ }
```

The `pub` keyword is disallowed because how would the compiler know which name to pick ? Calls use
the same format presented before: they are not affected by destructuring, which is internal only.

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

In today's Rust, this is perfectly valid, even when using all clippy warnings:

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

The first one is easily fixed by adding a type hint:

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

This would not be a function call (made clear by the `:` at the end). In case of several arguments,
it would be used as `new(adding:and:)`.

This would not raise a problem with type ascription because there would be no type after the `:`s,
especially after the last one and so the compiler would be able to unambiguously decide what is
happening.

It would be even easier in the case of a function call: `ffi_call(object, new(adding:))` because the
compiler would know what to expect as a type for the second parameter of `ffi_call` here.

## Interaction with closures

TODO

While closures live in the closed environment of Rust and cannot be handed out like function
pointers, they are similar at the usage point to function pointers. The Swift community has
experience with closures and named arguments and their solution has several edge cases and small
nits that make using closures with named arguments a little strange sometimes.

As such, closures and named arguments will be discussed later, in the [Unresolved
Questions][unresolved-questions] section.
