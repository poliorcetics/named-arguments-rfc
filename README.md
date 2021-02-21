# Named Arguments RFC

This repository hosts a **work-in-progress** RFC for named arguments in the Rust programming language.

It will be used as long as the RFC PR for it has not been made. After that, the modifications will
happen directly on the PR.

## Some goals for the RFC

- The solution **must** be backward compatible so that it can be backported to Rust Edition 2015,
  2018 and 2021. Even if a backport is not wanted, having it has a goal means this RFC should not
  conflict with existing features in one edition but not in another.

- The solution should improve readability/usability without requiring new keywords or much in the
  way of typing (so that programmers can use them without having to write a book and a half just
  for some non-critical feature).

- Clearly present other options and alternatives (maybe one of them is better and someone will see
  it before a wrong choice is made).

- *Default parameters* and *variadic parameters* are **out of scope**. They are orthogonal to named
  arguments and can be consdered with or without named arguments.

- *Overloading* is also **out of scope**. The named arguments solution proposed should not affect
  method resolution. This can evolve if a consensus is reached about that but such a significant
  change is probably outside of what can be proposed and designed by one person.

## TODO list

- [x] Intro / Summary
- [x] Motivation
- [x] Guide Level Explanation
- [ ] Reference Level Explanation (**working on this**)
- [ ] Drawbacks
- [x] Rationale and Alternatives (**partially done only**)
- [x] Prior Art
- [ ] Unresolved Questions
- [ ] Future Possibilities

- [ ] Cleanup files of their expectations (at the top)

## Style

To make documents easier to read and edit, try to limit line length to around a hundred (100)
characters. Moving a little overboad is okay if the paragraph ends here, like the first one of
this README.

This is not a hard requirement but it will help with proofreading and git diffs, which should
hopefully help improve the quality of the RFC.
