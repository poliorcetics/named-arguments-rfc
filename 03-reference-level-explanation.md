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

Traits are one of Rust most powerful feature and this RFC endavours to integrate well with them, to
avoid making them second class citizens.

One special case that comes to mind is closure and the `Fn` family of traits ([with an exemple from
the nomicon][nomicon-example]):

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

## Interaction with `#[no_mangle]`, `extern "C"` (or anything but the unstable Rust ABI)

Such functions are forbidden from using named arguments _if_ they are overloaded based on them. If
they are not, the function can be uniquely identified by just its name even for FFI, which is the
point of this attribute. Such functions would still be a warn-by-default lint because having
different calling styles for FFI and Rust seems like a Bad Idea(TM).

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

This one on the other hand, willwould not compile:

```rust
#[no_mangle]
extern "C" fn callback(pub return_code: u32) { /* ... */ }

#[no_mangle]
extern "C" fn callback(pub data: *const ()) { /* ... */ }
```
