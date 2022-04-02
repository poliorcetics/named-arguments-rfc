# Unresolved questions

- What parts of the design do you expect to resolve through the RFC process before this gets merged?
- What parts of the design do you expect to resolve through the implementation of this feature
  before stabilization?
- What related issues do you consider out of scope for this RFC that could be addressed in the
  future independently of the solution that comes out of this RFC?

## Defaults parameters

Default parameters and named arguments are often cited together but in reality they are quite
orthogonal features. They compose well together in several languages but that does not means they
are inseparable from a design point of view.

Whether they should be added to Rust or not should be considered in another RFC.

## Allowing keywords

See [Allow Keywords][allow-keywords] in Future Possibilities.

## Interactions with closure

One special case that comes to mind is closure and the `Fn` family of traits ([with an example from
the Nomicon][nomicon-example]):

```rust
struct Closure<F> {
    data: (u8, u16),
    func: F,
}

impl<F> Closure<F>
    where F: Fn(arg: &(u8, u16)) -> &u8,
{
    fn call(&self) -> &u8 {
        (self.func)(arg: &self.data)
    }
}
```

Should this impl also be valid for `Fn(&(u8, u16)) -> &u8` ? Or `Fn(other: &(u8, u16)) -> &u8` ?

I would argue yes, since [Calling a function with named arguments
indirectly][calling-a-function-with-named-arguments-indirectly] shows us names can be cast away when
needed: not allowing it would be an unnecessary papercut.

I would also argue no: named arguments should be considered like specified generic arguments:
`Ì: Iterator<Item = u16>` does not accept `I: Iterator<Item = u8>` so `impl` depending on named
arguments should take them into account.

This can be considered a form of specialization maybe, and so out of scope for this RFC. I do not
know the internals of rustc enough to know about how the `Fn` traits are implemented.
