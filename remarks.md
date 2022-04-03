# 2022-04-03 22:00

- Reordering named arguments when calling
  - Not clear enough why chosen
- Use types instead of names
  - Not always possible, see cargo examples
- Overloading
  - Very much against
  - Overloading resolution:
- Complexity
- Ambiguity
  - `fn foo(name (a, b): name)` is valid, `name` is parsed as a type
- Type ascription: when I asked about it, it seemed stalled and even moving backwards in such places
  as arguments
  - BUT it does conflict
- Unclear case with overloading
- `mut` misplaced, since it is linked to the pattern
- Ban with `#[no_mangle]`, instead make use of `#[export_name]`
