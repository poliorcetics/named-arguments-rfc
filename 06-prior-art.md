# Prior art
[prior-art]: #prior-art

Discuss prior art, both the good and the bad, in relation to this proposal.
A few examples of what this can include are:

- For language, library, cargo, tools, and compiler proposals: Does this feature exist in other
  programming languages and what experience have their community had?
- For community proposals: Is this done by some other community and what were their experiences with
  it?
- For other teams: What lessons can we learn from what other communities have done here?
- Papers: Are there any published papers or great posts that discuss this? If you have some
  relevant papers to refer to, this can serve as a more detailed theoretical background.

This section is intended to encourage you as an author to think about the lessons from other
languages, provide readers of your RFC with a fuller picture. If there is no prior art, that is
fine - your ideas are interesting to us whether they are brand new or if it is an adaptation from
other languages.

Note that while precedent set by other languages is some motivation, it does not on its own
motivate an RFC. Please also take into consideration that Rust sometimes intentionally diverges
from common language features.

## Past Rust-only considerations

This subsection focuses on the discussion that happened in the Rust world about named arguments.

> DISCLAIMER: I did not read *everything* in details, it is possible I missed things. I at least
> skimmed quickly over all of those listed below.

### Relevants discussions

Here are some past discussions on IRLO:

1. The [Wishlist issue](https://github.com/rust-lang/rfcs/issues/323) says named arguments (and
   other features) are thought about but the design space must be studied before rushing into one
   solution that will later prove insufficient or even plain wrong.
1. The (I think) [first RFC to propose them](https://github.com/rust-lang/rfcs/pull/257)
   introduced them in conjunction with *default parameters* and was closed as postponed. Some
   remarks on this RFC raised good points that have also been raised in subsequent RFCs, they will
   be listed in a section below.
1. [Struct sugar RFC #343](https://github.com/rust-lang/rfcs/pull/343): it proposed both a form of 
   named arguments and default parameters. It was marked as postponed and lots of people 
   commenting on the issue wanted less magical sugar.
1. [Keyword arguments #805](https://github.com/rust-lang/rfcs/pull/805): 

### Recurring points

Some arguments and opinions are recurring in most of the links above. I will try to list and
summarise most of them here.

- **Named arguments make changing function parameters names a breaking change**: this is certainly
 true. That's even the point of named arguments, to have a stable and clear interface to a
 function call, just like some `struct`s have public members or like `enum A { Variant { line: String } }`
 instead of simply `enum B { Variant(String) }`. This point is often raised to make a point about
 brittle syntax: named arguments should make it clear what is named and what is not so that
 programmers can be sure they are not breaking the public interface of something in a minor version
 change.

## What about other programming languages ?

Rust does not exist in a bubble and a lot of people have thought about named arguments for their
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

[Rosetta code]: https://rosettacode.org/wiki/Named_parameters

### Named arguments through direct types

This section is for languages that do not have named arguments directly but can use external
types to emulate them. Pretty much all languages can do that so this section is only for languages
that do **not** have named arguments directly.

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
more boilerplate (as in the long form of the C example above). Most statically typed languages
needs the type to be explicit too, adding more boilerplate.

In some languages, like JavaScript, creating an external type is not necessary, passing an
anonymous type with the expected properties is enough. This reduces the boilerplate, at the cost
of clarity: expected properties must be documented, often without the help of the language to check
for their existence before the function is called.

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

Some languages cannot use the previous method and must use a *Builder pattern* to get a form of
named arguments, as in the (shortened) Java example below. As with the last method, pretty much
every language can use this method. The list below will only consider languages that cannot apply
the previous (shorter) method nor have named arguments.

```java
processNutritionFacts(new NutritionFacts.Builder(240, 8)
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
boilerplate for two-parameter methods.

#### Languages using this method

- Java
- C# (before 4.0)

### Optional and/or unordered named arguments

This section is for languages that have named arguments but function calls can choose whether to
use them or not.

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

When languages have this feature, using named arguments is left to the  user, not the author of a
library but it is library authors that are responsible for the names and changing them is a
source-breaking change.

This places additionial burden on library authors without offering them much: since users can just
ignore the names authors are not able to rely on them to help with clarity and must instead often
design around them.

What's more, order is often not important as long as the names match which means a reviewer has to
be careful when two parameters are named similarly: there could be an uncaught bug hiding.

> From what I could find some domains force the use of named arguments when they are available,
> like Ada in military programs though I did not find conclusive proof one way or the other.

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
- Python
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
their clarity and convenience. The ability to turn them off is a must though, as seen in the
`sin(x: x)` example.

#### Languages using this feature

- AppleScript
- Objective-C
- OCaml
- Python
- Swift

### More on Python 3 and Swift

Python 3 and Swift are special and very informative examples because they are two languages where
it was possible to write named arguments only functions but the languages moved in opposite
directions: Python 3 gained a way to remove them in [PEP 570] while Swift continues to use them
more and more and functions in Swift are documented with the name of their arguments:
`open_port(_:withMaxConnexions:)`.

> Note: while this section concentrate on Swift, it must be noted that OCaml provides the same
> features using a different approach. See [this link][Ocaml-Rosetta] for more informations and
> an example. The example of Swift has been chosen because it is more widely used than OCaml and
> closer the C-family of languages, ensuring its syntax will be understood even by non-practioners,
> and especially the Rust community that is the target of this document. The same goes for
> Objective-C and AppleScript.

[Ocaml-Rosetta]: https://rosettacode.org/wiki/Named_parameters#OCaml
[PEP 570]: https://www.python.org/dev/peps/pep-0570/