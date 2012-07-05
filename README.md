kalc
====

kalc is a small functional programming language that (gasp) borrows a lot of its
syntax from the Excel formula language.

ikalc
-----

kalc comes with its own repl, known as `ikalc`. Start it up in your console by
typing in `ikalc`

Syntax
------

kalc is a tiny language, and it has very little syntax. It does support
functions, variable assignment, and arithmetic.

Numbers
-------

All numbers are floating point.

    1 =\> 1.0 2.020 =\> 2.02 1.23E =\> 12300000000.0

Arithmetic
----------

    1 + 1 / (10 \* 100) - 3 + 3 - (3 - 2) 1 \> 1 SUM(1, 2, 3, 4, 5)

Arithmetic is standard infix with nesting via parenthesis.

Logical operations
------------------

    1 \> 2 ? 1 : 3 # Ternary (1 || 2) \> 3 1 \> 2 or 3 <2 # false OR(1 > 2, 3 \<
    2, 8 == 8) # true

Variable assignment
-------------------

    a := 1 b := 2 d := a + b

Functions
---------

You can create functions in kalc:

    DEFINE FOO(a, b) { a + b }

You can also call functions in kalc:

    \> a = FOO(2, 3) \> a 5

There are a few examples of functions in `lib/stdlib.kalc`

Built-in functions
------------------

There are some built-in functions (in `lib/kalc/interpreter.rb`). They are based
on the Excel formula functions, so you should see some overlap.

Some of them are:

    IF, OR, NOT, AND, RAND, SYSTEM, ISLOGICAL, ISNONTEXT, ISNUMBER, ISTEXT, ABS,
    DEGREES, PRODUCT, RADIANS, ROUND, SUM, TRUNC, LN, ACOS, ACOSH, ASIN, ASINH,
    ATAN, ATANH, CBRT, COS, COSH, ERF, ERFC, EXP, GAMMA, LGAMMA, LOG, LOG2,
    LOG10, SIN, SINH, SQRT, TAN, TANH, UPPER, LOWER, CHOMP, CHOP, CHR, CLEAR,
    COUNT, DOWNCASE, HEX, INSPECT, INTERN, TO_SYM, LENGTH, SIZE, LSTRIP, SUCC,
    NEXT, OCT, ORD, REVERSE, RSTRIP, STRIP, SWAPCASE, TO_C, TO_F, TO_I, TO_R,
    UPCASE, P, PP, PUTS, PLUS_ONE, MINUS_ONE, SQUARE, CUBE, FIB, FACTORIAL,
    TOWERS_OF_HANOI

Loops
-----

There are no looping mechanisms to speak of, but recursion works (pretty) well.  
**Note:** *go too deep and you might blow the stack!*

    DEFINE SAMPLE_LOOP(a) { PUTS(a) IF(a == 1, 1, SAMPLE_LOOP(a - 1)) }

There are a few examples of loops via recursion in `lib/stdlib.kalc`

Weirdness
---------

And here is where it gets a bit weird. It has to look a bit like Excel, so you
can expect things to look odd in places.

For example, here is how you compare 2 variables:

    # Assign '1' to 'a' and '2' to 'b' a := 1 b := 2

    # Does 'a' equal 'b'? a = b \> false

    # Also, you can do this: a == b \> false

    (a == a) && (b = b) \> true

'=' and '==' are both equality operators. Use ':=' for assignment.

More inside
-----------

Not everything is documented yet. As you can see, it is a mix of a lot of
different ideas. The goal is to have an excel-like language that is somewhat
functional.

Contributing
------------

Fork on GitHub and after you've committed tested patches, send a pull request.
