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

### Allowing overloading

The form of overload proposed would notably allow moving the standard library mostly without
troubles: `Option::ok_or` could continue to exist and be deprecated in favor of `Option::ok(or:)`.

The proposed rules for overloading would mean all currently existing Rust code would stay valid
since the default resolution for `GetClosure::get(my_function)` would never call a function with
named arguments.

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
