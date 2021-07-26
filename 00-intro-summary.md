This is my first attempt at an RFC, any feedback is welcome :).

Named arguments have been proposed before, several times, in several forms. This document will list
below some links found on this forum about them or in past RFCs. It will also review what exists in
other programming languages before presenting this RFC's solution.

But first, some goals for this RFC:

- The solution **must** be backward compatible so that it can be backported to Rust Edition 2015,
  2018 and 2021. Even if a backport is not wanted, having it has a goal means this RFC should not
  conflict with features existing in one edition but not in another.
- The solution should improve readability/usability without requiring new keywords or much in the
  way of typing (so that programmers can use them without having to write a line and a half just for
  some non-critical feature).
- Clearly present other options and alternatives (maybe one of them is better and someone will see
  it before a wrong choice is made).
- _Default parameters_ and _variadic parameters_ are **out of scope**. They are orthogonal to named
  arguments and can be considered with or without named arguments.
- _Overloading_ is **in scope**. The named arguments solution proposed will affect function
  resolution.

---

- Feature Name: `named_arguments`
- Start Date: **TO FILL WITH TODAY'S DATE**
- RFC PR: [rust-lang/rfcs#0000](https://github.com/rust-lang/rfcs/pull/0000)
- Rust Issue: [rust-lang/rust#0000](https://github.com/rust-lang/rust/issues/0000)

# Summary

[summary]: #summary

This RFC introduces _named arguments_ for Rust. Named arguments are the ability to call a function ,
method or closure while precising the caller-facing name of the arguments, greatly improving clarity
in many situations. Of course functions where the argument is already clear do not have to use them:
`sin(x: x)` would be ridiculous and redundant. Named arguments as proposed here are **not**
source-breaking: existing functions and methods will continue to work without any change. Named
arguments as proposed here are **opt-in**. Changing the name of `f(a: usize)` to `f(b: usize)` will
**not** be a breaking change, just like it is not today: once again, the goal is not to force them
on developers but to provide another option that has seen huge success in other languages in a way
that fit with Rust.

Named arguments also introduce a limited form a function overloading that is easy to check for both
a human and the compiler and can be applied to profit plainly from heavily used function names like
`new`.

An example in `Python` for clarity:

```python
def open_port(port: int, max_connexions: int, timeout: int):
    print(f"Port: {port}")
    print(f"Max conn: {max_connexions}")
    print(f"Timeout: {timeout}")

# Calling the function with names for the arguments.
open_port(port=12345, max_connexions=10, timeout=60)
```
