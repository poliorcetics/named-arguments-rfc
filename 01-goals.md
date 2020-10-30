# Goals

But first, some goals for this post:

- The solution **must** be backward compatible so that it can be backported to Rust Edition 2015,
  2018 and possibly 2021 (depending on the time (and if) this is accepted).
- The solution should improve readability/usability without requiring new keywords or much in the
  way of typing (so that programmers can use them without having to write a book and a half just
  for some non-critical feature).
- Clearly present other options and alternatives (maybe one of them is better and someone will see
  it before a wrong choice is made).
- *Default parameters* and *variadic parameters* are **out of scope**. They are orthogonal to named
  arguments and can be consdered with or without named arguments.
- *Overloading* is also **out of scope**. The *named arguments* solution proposed should not affect
  method resolution. This can evolve if a consensus is reached about that but such a significant
  change is probably outside of what can be proposed and designed by one person.
