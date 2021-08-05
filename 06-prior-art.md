# Prior art

[prior-art]: #prior-art

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

### Relevants discussions

Here are some past discussions on IRLO and past RFCs:

1. The [Wishlist issue](https://github.com/rust-lang/rfcs/issues/323) says named arguments (and
   other features) are thought about but the design space must be studied before rushing into one
   solution that will later prove insufficient or even plain wrong. Even if this RFC is not approved
   I hope the section below about other programming languages listing the different possibilites
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
  practionners of the language, notably library designers. Another example, from Rust even, is
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
differents options with a summary at the end, not a list of functionalities per language.

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

- ALGOL 68 (not kwown to be used in any real code though)
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

This places additionial burden on library authors without offering them much: since users can just
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
- PowerShell
- Python (2 & 3)
- R (will fill missing named args with unnamed args in the given order, very brittle)
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
> the C-family of languages, ensuring its syntax will be understood even by non-practioners, and
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
