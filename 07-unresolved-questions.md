# Unresolved questions

[unresolved-questions]: #unresolved-questions

- What parts of the design do you expect to resolve through the RFC process before this gets merged?
- What parts of the design do you expect to resolve through the implementation of this feature
  before stabilization?
- What related issues do you consider out of scope for this RFC that could be addressed in the
  future independently of the solution that comes out of this RFC?

## Interactions between closures and named arguments

- Allow them or not in closure def ?
- Are they strict or can they be renamed from a non-conforming function ?
- How is it handled at the compiler/Fn-traits level ?
