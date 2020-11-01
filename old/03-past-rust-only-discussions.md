# Past Rust-only considerations

This sections focuses on the discussion that happened in the Rust world about *named arguments*.

DISCLAIMER: I did not read *everything* in details, it is possible I missed things. I at least
skimmed quickly over all of them.

## Relevants discussions

Here are some past discussions on IRLO:

1. The [Wishlist issue](https://github.com/rust-lang/rfcs/issues/323) says *named arguments* (and
   other features) are thought about but the design space must be studied before rushing into one
   solution that will later prove insufficient or even plain wrong.
1. The (I think) [first RFC to propose them](https://github.com/rust-lang/rfcs/pull/257)
   introduced them in conjunction with *default parameters* and was closed as postponed. Some
   remarks on this RFC raised good points that have also been raised in subsequent RFCs, they will
   be listed in a section below.
1. [Struct sugar RFC #343](https://github.com/rust-lang/rfcs/pull/343): it proposed both a form of 
   *named arguments* and *default parameters*. It was marked as postponed and lots of people 
   commenting on the issue wanted less magical sugar.
1. [Keyword arguments #805](https://github.com/rust-lang/rfcs/pull/805): 

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
with *named arguments*. Since many of those syntaxes have been proposed in several RFCs or in their
comments I will not attribute them to one in particular.

They are numbered to simplify discussions about them. Edits to this section will not move the
numbers so that comments stay as relevant as possible.

I also try to always use the same function definition so that the differences are the syntax for
*named arguments*.

### In definitions

1. `fn fun(anonymous: &str, named: &str)`: using the name is optional and it can be used by the
   caller or not. **Very brittle** since all parameters names are immediately part of the public
   API and cannot be changed anymore.
1. `fn fun(anonymous: &str, pub named: &str)`: using the existing `pub` keyword to mark a paramter
   as public, this has the advantage of not introducing a new keyword and keeping the meaning of
   the selected keyword the same. Forms like `pub(crate)` are always disallowed though, the
   parameter is either fully public or it is not.
1. 

### In calls

0. Function call as they are currently: `fun("anonymous", "value")`
1. `fun("anonymous", named: "value")`
1. `fun("anonymous", named = "value")`

