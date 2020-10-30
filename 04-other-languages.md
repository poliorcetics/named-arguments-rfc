# What about other programming languages ?

Rust does not exist in a bubble and a lot of people have thought about *named arguments* for their
preferred language. This section will look at what other languages have done and how (and if) they
solved the problems that *named arguments* attempts to solve.

Since many languages have them in some form or other this will be more of a list presenting the
differents options with a summary at the end, not a list of functionalities.

Note that languages may appear in several categories: they are not exclusive. All languages ever
created are not listed and it is entirely possible a solution (and the language using it) was
missed. If you find that is the case, please signal it to help improve this section.

Languages that have direct support for named arguments will not be listed in the other categories,
even if they fit in them

## Structured records

This section is for languages that do not have *named arguments* directly but can use external
types to emulate them.

An example in `C`:

```c
#include <stdio.h>

struct OpenPortOptions {
    unsigned int port;
    unsigned int max_connexions;
};

void open_port(const struct OpenPortOptions options) {
    printf("port: %d\n", options->port);
    printf("max connexions: %d\n", options->max_connexions);
}

// Call with:
int main(void) {
    // Short version, needs a cast, cannot be reused, avoids declaring a local variable.
    open_port((struct OpenPortOptions){ .port = 12345, .max_connexions = 10 });

    // Long version, can be reused if necessary.
    const struct OpenPortOptions options = { .port = 12345, .max_connexions = 10 };
    open_port(options);
    // It is possible to invert the order of the members.
    const struct OpenPortOptions options_2 = { .max_connexions = 10, .port = 54321 };
    open_port(options_2);
    return 0;
}
```

In such languages an external type is often necessary to implement *named arguments*. If you have
functions taking another set of arguments, you will need another type. Depending on the language,
types can be created inline (`call(MyType { name1: val1, ... })`, as in Rust) or not, which adds
more boilerplate (as in the long form of the C example above).

In some languages, like JavaScript, creating an external type is not necessary, passing an
anonymous type with the expected properties is enough. This reduces the boilerplate, at the cost
of clarity: expected properties must be documented, often without the help of the language to check
their existence.

While this solution works when it is only needed for a few specific functions, it does not scale
well, especially if the concerned functions are public: the helper types will have to be too,
widening API surface and adding boilerplate.

### Languages using this method

- ALGOL 68 (not kwown to be used in any real code though)
- AppleScript
- Bracmat
- C
- C++
- Forth
- Go
- Haskell
- JavaScript
- jq
- Lingo
- Perl
- PHP
- StandardML
- Tcl
- Wren
