# Drawbacks

[drawbacks]: #drawbacks

Why should we _not_ do this?

## Overloading

Historically (and not limited to Rust), overloading has been seen as a mixed bag: it allows lots of
expressiveness but can quickly become unclear: which type is passed ? Which overload is called ? Is
that constructor the move or copy one ?

This has mostly not been a problem for Swift and Python, because their use of overloading is based
on something more visible, named arguments, not types invisible without hints. This is the form
proposed for Rust and as such, it will not fall prey to the lack of clarity that simple
type/number-based overload is subject to.
