# kalc

`kalc` is a small Excel-flavored, expression-based language implemented in
Ruby. It borrows the feel of spreadsheet formulas, but runs as plain text:
you can store formulas in files, run them from the command line, experiment in
a REPL, or embed the runtime in a Ruby application.

The language leans into spreadsheet-style behavior:

- variables are lazy formulas, not eager assignments
- builtins are modeled after familiar Excel functions
- arrays are rectangular values with row and column operations
- user-defined functions and recursion let you go beyond spreadsheet cells

`kalc` is not a spreadsheet UI. There are no `A1:B10` references today; arrays
are the current collection model.

## Highlights

- Excel-like expressions with `IF`, `IFS`, `SWITCH`, `CHOOSE`, `SUM`, `ROUND`,
  `TEXTJOIN`, `SUBSTITUTE`, `MATCH`, `XLOOKUP`, `FILTER`, `SORT`, `UNIQUE`,
  `SEQUENCE`, and more
- lazy assignment semantics that behave more like spreadsheet formulas than
  local variables
- first-class array literals such as `[1; 2; 3]` and
  `["name", "score"; "Ada", 98]`
- custom parser and embeddable Ruby runtime
- command-line runner, interactive REPL, and Ruby API
- example programs under [`examples/`](examples/)
  backed by executable specs in
  [`spec/examples_spec.rb`](spec/examples_spec.rb)

## Quick Start

From a source checkout:

```bash
mise install
bin/setup
ruby bin/kalc examples/invoice.kalc
ruby bin/ikalc
```

Example output:

```text
Ada Lovelace owes 102.98 (subtotal 98.00, discount 9.80, shipping 7.50, tax 7.28)
```

If you want debug output in the REPL, start it with:

```bash
KALC_DEBUG=1 ruby bin/ikalc
```

## Command Line

Run a `.kalc` file:

```bash
ruby bin/kalc examples/spaceport_dashboard.kalc
```

Start the interactive shell:

```bash
ruby bin/ikalc
```

The REPL supports a few built-in commands:

- `functions` prints registered functions
- `variables` prints currently defined variables
- `ast` prints the last parsed AST
- `reload` rebuilds the runtime and reloads the stdlib
- `quit` and `exit` leave the REPL

## Language Overview

### Numbers, Strings, and Booleans

`kalc` prefers `BigDecimal` for decimal arithmetic, while some math-library
functions return other Ruby numerics where that makes sense.

```kalc
1
2.020
TRUE
FALSE
"hello"
```

### Arithmetic and Conditionals

Arithmetic uses standard infix operators and parentheses.

```kalc
1 + 1 / (10 * 100) - 3 + 3 - (3 - 2)
SUM(1, 2, 3, 4, 5)
ROUND(19.99 * 1.0825, 2)
```

Conditionals can be written with the ternary operator or Excel-style builtins.

```kalc
1 > 2 ? "no" : "yes"
IF(2 < 3, "ok", "nope")
IFS(1 > 2, "no", 2 > 1, "yes")
SWITCH(2, 1, "one", 2, "two", "other")
CHOOSE(2, "alpha", "beta", "gamma")
```

Infix logical operators short-circuit:

```kalc
FALSE && SYSTEM("echo nope")
TRUE || SYSTEM("echo nope")
```

`SYSTEM` is intentionally disabled, so short-circuiting matters.

### Lazy Variables

Assignments use `:=`. Variables store formulas and are re-evaluated when read,
which gives `kalc` a spreadsheet-like feel.

```kalc
price := 10
line_total := price * 2
price := 20
line_total
```

That evaluates to `40`, not `20`, because `line_total` tracks the formula
`price * 2`.

Circular references are rejected:

```kalc
a := a + 1
```

### Quoted Identifiers

Quoted identifiers are useful when a variable name needs spaces, punctuation,
or other characters that normal identifiers do not allow.

```kalc
'Invoice Total' := 98
'Tax Rate (%)' := 8.25
'This \' is valid' := 1
```

### Arrays

Arrays use square brackets. Commas separate columns and semicolons separate
rows.

```kalc
[1; 2; 3]
[1, 2, 3]
["name", "score"; "Ada", 98; "Grace", 100]
```

Arrays work with aggregate and lookup functions:

```kalc
scores := [98; 100; 99]
AVERAGE(scores)
INDEX(scores, 2)
XLOOKUP("Grace", ["Ada"; "Grace"; "Katherine"], scores)
FILTER([10; 20; 30], [FALSE; TRUE; TRUE])
```

The current array and table-oriented builtins include:

- `ROWS`, `COLUMNS`, `INDEX`
- `MATCH`, `XLOOKUP`
- `FILTER`, `SORT`, `UNIQUE`, `TRANSPOSE`, `SEQUENCE`

### User-Defined Functions

You can define functions directly in `kalc`:

```kalc
DEFINE DOUBLE(x) {
  x * 2
}

DOUBLE(21)
```

Recursion works too:

```kalc
DEFINE FACT(n) {
  IF(n <= 1, 1, n * FACT(n - 1))
}

FACT(5)
```

There is no dedicated loop syntax today, so recursion is the main way to
express repeated work inside the language.

## Builtins

Builtins live under
[`lib/kalc/builtins/`](lib/kalc/builtins/).
Some representative groups:

- Control flow: `IF`, `IFS`, `SWITCH`, `CHOOSE`, `AND`, `OR`, `NOT`
- Math and aggregates: `SUM`, `AVERAGE`, `COUNT`, `COUNTA`, `MIN`, `MAX`,
  `ABS`, `ROUND`, `ROUNDUP`, `ROUNDDOWN`, `INT`, `MOD`, `POWER`, `PI`,
  `SUMIF`, `COUNTIF`
- Strings: `CONCATENATE`, `TEXTJOIN`, `FIND`, `SEARCH`, `SUBSTITUTE`, `LEFT`,
  `RIGHT`, `MID`, `REPLACE`, `TRIM`, `LOWER`, `UPPER`, `VALUE`, `FIXED`,
  `DOLLAR`
- Arrays and lookups: `ROWS`, `COLUMNS`, `INDEX`, `MATCH`, `XLOOKUP`,
  `FILTER`, `SORT`, `UNIQUE`, `TRANSPOSE`, `SEQUENCE`
- Regex: `REGEXP_MATCH`, `REGEXP_REPLACE`
- Debugging: `P`, `PP`, `PUTS`

The stdlib in
[`lib/kalc/stdlib.kalc`](lib/kalc/stdlib.kalc)
adds a few fun helpers like `FIB`, `FACTORIAL`, and `TOWERS_OF_HANOI`.

## Ruby API

### High-Level API: `Kalc::Runner`

[`Kalc::Runner`](lib/kalc.rb) is the
easiest way to embed `kalc`. It keeps the parser, interpreter, and environment
alive across calls, so state persists naturally.

```ruby
require "kalc"

runner = Kalc::Runner.new
runner.run("tax := 0.0825")
runner.run("price := 19.99")

result = runner.run("ROUND(price * (1 + tax), 2)")
result.class
# => BigDecimal

result.to_s("F")
# => "21.64"
```

You can reset the runtime with `reload`:

```ruby
runner.reload
```

### Parsing Without Running

Use [`Kalc::Grammar`](lib/kalc/grammar.rb)
if you want the AST without evaluating it.

```ruby
require "kalc"

grammar = Kalc::Grammar.new
ast = grammar.parse("SUM([1; 2; 3])")

ast.class
# => Kalc::Ast::Program
```

Parse failures raise
[`Kalc::ParseError`](lib/kalc/grammar/parse_error.rb),
which includes line and column information.

### Lower-Level Runtime Control

Use [`Kalc::Interpreter`](lib/kalc/interpreter.rb)
if you want to manage parsing and evaluation separately.

```ruby
require "kalc"

grammar = Kalc::Grammar.new
interpreter = Kalc::Interpreter.new
interpreter.load_stdlib(grammar)

ast = grammar.parse('XLOOKUP("Grace", ["Ada"; "Grace"], [98; 100])')
result = interpreter.run(ast)

result.to_s("F")
# => "100.0"
```

### Error Handling

```ruby
require "kalc"

runner = Kalc::Runner.new

begin
  runner.run("a := a + 1")
rescue Kalc::CircularReferenceError, Kalc::ParseError => error
  warn error.message
end
```

Common runtime result types include:

- `BigDecimal` for most decimal arithmetic
- `String` for text results
- `TrueClass` and `FalseClass` for booleans
- [`Kalc::Ast::ArrayValue`](lib/kalc/ast.rb)
  for array results

`ArrayValue` exposes useful methods such as `rows`, `row_count`,
`column_count`, `vector?`, and `to_s`.

## Example Gallery

The repository includes a playful set of examples under
[`examples/`](examples/).
Every file is covered by
[`spec/examples_spec.rb`](spec/examples_spec.rb).

Some good starting points:

- [`examples/add.kalc`](examples/add.kalc)
  - tiny arithmetic starter
- [`examples/invoice.kalc`](examples/invoice.kalc)
  - lazy formulas, formatting, and totals
- [`examples/gradebook.kalc`](examples/gradebook.kalc)
  - conditionals and weighted scoring
- [`examples/arrays.kalc`](examples/arrays.kalc)
  - arrays, aggregation, and reporting
- [`examples/crew_lookup.kalc`](examples/crew_lookup.kalc)
  - `XLOOKUP` and table data
- [`examples/leaderboard.kalc`](examples/leaderboard.kalc)
  - sorting and ranking
- [`examples/restock_queue.kalc`](examples/restock_queue.kalc)
  - filtering and text assembly
- [`examples/sequence_board.kalc`](examples/sequence_board.kalc)
  - generated arrays via `SEQUENCE`
- [`examples/transpose_schedule.kalc`](examples/transpose_schedule.kalc)
  - matrix transposition
- [`examples/unique_topics.kalc`](examples/unique_topics.kalc)
  - `UNIQUE` and text reporting
- [`examples/spaceport_dashboard.kalc`](examples/spaceport_dashboard.kalc)
  - a larger showcase with lookups and summaries

## Development

`kalc` uses `mise` to manage the Ruby version declared in
[`.ruby-version`](.ruby-version) and
[`.tool-versions`](.tool-versions).

```bash
mise install
bin/setup
bundle exec rake spec
bundle exec rubocop
```

Useful development entry points:

- `bin/console` opens an IRB session with a ready-to-use `runner`
- `bin/ikalc` starts the interactive shell
- `bundle exec rspec spec/examples_spec.rb` runs the example gallery checks

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md)
for workflow details.
