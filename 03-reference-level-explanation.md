# Reference-level explanation
[reference-level-explanation]: #reference-level-explanation

This is the technical portion of the RFC. Explain the design in sufficient detail that:

- Its interaction with other features is clear.
- It is reasonably clear how the feature would be implemented.
- Corner cases are dissected by example.

The section should return to the examples given in the previous section, and explain more fully how
the detailed proposal makes those examples work.

## Two (or more) named arguments with the same public name

There are three cases for this situation:

```rust
fn func1(pub name: u32, pub name: u32) { /* ... */ }
fn func2(pub name: u32, name hidden: u32) { /* ... */ }
fn func3(name hidden1: u32, name hidden2: u32) { /* ... */ }
```

- `func1` is clearly impossible because `name` would have two different meaning inside the function's
  definition. Aside from already being an error in today's Rust, it is simply impossible to do.

- `func2` and `func3` could work in theory: named arguments as proposed in this RFC are position-based
  and their internal names are different: just like two arguments can have the same type without
  ambiguity, those functions could be allowed.

But named arguments are a feature designed to improve clarity at the call site and calling
`register(name: param, name: param2)` is just as unclear (and arguably worse) than `register(param, param2)`
so this RFC argues for all those forms to either produce an unconditional error (`func1`) or to produce
an error-by-default lint (`func2` and `func3`).

The error-by-default lint is here because it is theoretically possible for very specific cases to
need the same public name twice, but the Swift community has not found such use cases despite their
heavy use of named arguments.

## Interaction with traits

Parameter names are not part of a trait API in today's Rust, justly so: they are helpful guide when
looking at documentation but are not part of the public API when calling the method.

This RFC makes the *public* part of a named argument an API requirement when implementing the trait.

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
avoid making them second class citizen..

## Interaction with function pointers

## Interaction with closures

## Interaction with destructuring

```rust
fn process_pair( (id, name): (u32, String) ) { unimplemented!() }
```

## Interaction with type ascription

> Citation from a past RFC:
>
> Using = would be ambiguous, as foo = bar is a valid expression (returning ()). Using : as the RFC
> suggests would be unambiguous today, but become ambiguous in the future if we ever get type
> ascription (the ability to say let foo = bar(): int;, which uses a colon to specify the type of
> an expression), which is something that has been wanted for a long time. An alternative that is
> unambiguous even with type ascription would be =>.
