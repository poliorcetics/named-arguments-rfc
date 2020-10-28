# Motivation

- *Named arguments* increase readability.

```swift
// Which is the insertion index and which is the element ?
my_vec.insert(2, 3)

// Clearer without asking for much
my_vec.insert(2, at: 3)

// Maybe too much named arguments ?
my_vec.insert(elem: 2, at: 3)
```

- *Named arguments* are self documenting.

In the example code above it is easy for a developer to remember which argument does what simply
by looking at the method call, without having to write a little toy example or look at the
documentation for the type (or the trait).

- *Named arguments* are simple to create compared to the other options.

In all languages that have them, named arguments are simple to create: they do not require a new
type and they do not require a builder pattern (and so another type). This does not means that
builder patterns or new types are useless: I argue that the use cases are simply not the same.
*Named arguments* should be used to clarify function calls, **not** write functions and methods
with 13 parameters, 7 of which are optional: a builder would be more useful in this situation.

- *Named arguments* are simple to use compared to the other options.

Calling a builder for the `my_vec.insert` call above is clearly overengineering and creating a type
for such a simple operation is overkill too. *Named arguments* are made to fill this spot where the
other solutions are too big for what's intended.

- *Named arguments* can be combined with other features to increase readability even more.

It is possible to combine builders/new types with *named arguments* without problems:

```rust
// Hypothetical Rust syntax for named arguments that does not conflict with
// a ConnectionOptions type.
pool.connect("https://a.b.c/endpoint/", with: ConnectionOptions {
timeout: 200,
account: "name",
..Default::default()
});
```

