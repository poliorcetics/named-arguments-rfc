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

