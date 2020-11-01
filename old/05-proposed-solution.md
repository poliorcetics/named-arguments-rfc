# Proposed solution

This section presents the solution as well as its consequences on Rust, notably its interactions
with other related features.

## Interaction with closures

## Interaction with destructuring

## Interaction with type ascription

Using = would be ambiguous, as foo = bar is a valid expression (returning ()). Using : as the RFC suggests would be unambiguous today, but become ambiguous in the future if we ever get type ascription (the ability to say let foo = bar(): int;, which uses a colon to specify the type of an expression), which is something that has been wanted for a long time. An alternative that is unambiguous even with type ascription would be =>.
