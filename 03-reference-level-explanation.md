# Reference-level explanation
[reference-level-explanation]: #reference-level-explanation

This is the technical portion of the RFC. Explain the design in sufficient detail that:

- Its interaction with other features is clear.
- It is reasonably clear how the feature would be implemented.
- Corner cases are dissected by example.

The section should return to the examples given in the previous section, and explain more fully how
the detailed proposal makes those examples work.

## Interaction with closures

## Interaction with destructuring

## Interaction with type ascription

> Citation from a past RFC:
>
> Using = would be ambiguous, as foo = bar is a valid expression (returning ()). Using : as the RFC
> suggests would be unambiguous today, but become ambiguous in the future if we ever get type
> ascription (the ability to say let foo = bar(): int;, which uses a colon to specify the type of
> an expression), which is something that has been wanted for a long time. An alternative that is
> unambiguous even with type ascription would be =>.
