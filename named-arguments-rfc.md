This is my first attempt at an RFC, any feedback is welcome :slight_smile:.

Named arguments have been proposed before, several times, in several forms. I will list below some
links I found on this forum about them. I will also try to review what exists in other programming
languages I know of before presenting the solution I have.

## Goals

But first, some goals for this post:

- The solution **must** be backward compatible so that it can be backported to Rust Edition 2015,
  2018 and possibly 2021 (depending on the time (and if) this is accepted).
- The solution should improve readability/usability without requiring new keywords or much in the
  way of typing (so that programmers can use them without having to write a book and a half just
  for some non-critical feature).
- Clearly present other options (maybe one of them is better and I just didn't see it and someone
  else will).
- *Default parameters* and *variadic parameters* are **out of scope**. They are orthogonal to named
  arguments and can be consdered with or without named arguments.

# Rust-only considerations

## Relevants discussions

Here are some past discussions on IRLO:

- The [Wishlist issue](https://github.com/rust-lang/rfcs/issues/323) says *named arguments* (and
  other features) are thought about but the design space must be studied before rushing into one
  solution that will later prove insufficient or even plain wrong.
- The (I think) [first RFC to propose them](https://github.com/KokaKiwi/rfcs/blob/default_args/active/0000-default-arguments.md)
  introduced them in conjunction with *default parameters* and was closed as postponed. Some
  remarks on this RFC raised good points that have also been raised in subsequent RFCs, they will
  be listed in a section below.

## Recurring points

Some arguments and opinions are recurring in most of the links above. I will try to list and
summarise most of them here.

- **Named arguments make changing function parameters names a breaking change**: this is certainly
 true. That's even the point of *named arguments*, to have a stable and clear interface to a 
 function call, just like some `struct`s have public members or like `enum A { Variant { line: String } }`
 instead of simply `enum B { Variant(String) }`. This point is often raised to make a point about
 brittle syntax: *named arguments* should make it clear what is named and what is not so that 
 programmers can be sure they are not breaking the public interface of something in a minor version
 change.

## Past proposed syntaxes

I will here summarise the proposed syntaxes I could find for both definition and calls to functions
with named arguments. Since many of those syntaxes have been proposed in several RFCs or in their
comments I will not attribute them to one in particular.

They are numbered to simplify discussions about them.

### In definitions [def]

1. `fn name(a: &str, named: &str)`: using the name is optional and it can be used by the caller or
   not.

### In calls [call]

1. `function_call("anonymous argument", named: "argument")`
2. `function_call("anonymous argument", named = "argument")`

# What about other programming languages ?
