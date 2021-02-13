# Motivation
[motivation]: #motivation

The main point of this section is that named arguments make for harder to misuse
interfaces through clarity and simplicity of both declaration and usage.

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

In the example code above it is easy for a developer to remember which argument does what simply
by looking at the method call, without having to write a little toy example or look at the
documentation for the type (or the trait). Autocompletion can help by providing the names and filling
them in advance, meaning no more typing for most people, just clearer code. Code is also read more
than it is written, the clearer it is, the less mistakes slip through reviews.

- Named arguments are simple to **create** compared to the other options.

In all languages that have them, named arguments are simple to create: they do not require a new
type and they do not require a builder pattern (and so another type). This does not means that
builder patterns or new types are useless: I argue that the use cases are simply not the same.
Named arguments should be used to clarify function calls, **not** write functions and methods
with 13 parameters, 7 of which are optional: a builder would be more useful in this situation.

- Named arguments are simple to **use** compared to the other options.

Calling a builder for the `my_vec.insert` call above is clearly overengineering and creating a type
for such a simple operation is overkill too. Named arguments are made to fill this spot where the
other solutions are too big for what's intended but clarity is lost without something more than
positional arguments.

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

Named arguments allow iterating quickly without sacrificing readability, because they are dead simple.
There's no need to create new types or make up long function names.

As an example: the (amazing) `cargo` tool [would have a use for named arguments][cargo-named-args]:

```rust
// Code in cargo

compile_opts.filter = ops::CompileFilter::new(
    LibRule::Default,   // compile the library, so the unit tests can be run filtered
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
    examples: FilterRule::none(), // --examples option
    benches: FilterRule::none(), // --benches option
); // also, specify --doc to run doc tests filtered
```

- Improve soundness and safety.

The documentation for [`Vec::reserve_exact`](https://doc.rust-lang.org/std/vec/struct.Vec.html#method.reserve_exact)
shows clearly the parameter is for *additional* capacity. But is it always clear in code ?

```rust
let mut vec = vec![1];
// Is this `additional` or `total` capacity ? The name of the method is quite
// unclear here.
vec.reserve_exact(10);
```

An argument against named argument is that hints like those provided by Rust-Analyzer are here for
those cases. This is true, but they are not always available. They can be disabled, reviewing a PR
through a web interface does not have them, reading code on Github will not show them, maybe your
coworker does not like them, there are many reasons for them not to appear. Named arguments are part
of the code, they always appear when intended to. Just like types, they help by adding another
layer of clarity to code, which helps with soundness and safety, and just like types can be inferred
when writing `let a = b + c`, named arguments as proposed here are not mandatory: forcing `sin(x: x)`
is **not** improving anything.

- Improve coherence in the language.

Named arguments already exists for `struct`s today: `Latitude { x: 42.1, y: 84.2 }`, having named
arguments for functions can be seen as an extension of that capability.

The previous paragraph opens an argument against: `Wrapper(x)` does not have named arguments and it
is quite clear. I would argue this is completely and utterly false: the argument name **is** the
name of the type itself. Wrapper types are here to increase clarity and provide additional guarantees
through the type system, and they do so by being explicit (`NonZeroUsize` and friends are wrapper
types that make their usage clear through their name for example).

[cargo-named-args]: https://github.com/rust-lang/cargo/blob/b842849732f89df8675eb2d933c384d6338e4466/src/bin/cargo/commands/test.rs#L107-L113
