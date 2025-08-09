# Miracles

**⚠️ Experimental Project**: This is an experimental AST-based macro system for the Gleam programming language. It's a proof-of-concept exploring code generation through comment annotations.

[![Package Version](https://img.shields.io/hexpm/v/miracles)](https://hex.pm/packages/miracles)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/miracles/)

## Overview

Miracles is an experiment in bringing macro-like capabilities to Gleam through comment annotations and AST manipulation. The system parses Gleam code, finds annotation comments, and applies transformations to generate new functions.

## Installation

```sh
gleam add miracles@1
```

## Quick Example

**Input (`src/input_code.gleam`):**
```gleam
// @make_printer
pub type Cardinal {
  North
  East
  South
  West
}
```

**Generated Output (`src/output_code.gleam`):**
```gleam
import gleam/io

pub type Cardinal {
  North()
  East()
  South()
  West()
}

pub fn print_cardinal(cardinal: Cardinal) {
  case cardinal {
    North() -> io.println("North")
    East() -> io.println("East")
    South() -> io.println("South")
    West() -> io.println("West")
  }
}
```

## How It Works

1. **Annotation**: Add a comment annotation above your type definition (e.g., `// @make_printer`)
2. **Processing**: Run the macro system to parse your code into an AST using `glance`
3. **Generation**: The system finds annotations and applies the corresponding macro function
4. **Output**: Generated code is written to the output file with new functions added

## Available Macros

### `@make_printer`

Generates a printer function for custom types that prints the variant name for each constructor.

## Usage

```sh
gleam run   # Process input_code.gleam and generate output_code.gleam
```

The system reads from `src/input_code.gleam` and writes the transformed code to `src/output_code.gleam`.

## Experiment Status

This is a learning project exploring:
- AST manipulation in Gleam using the `glance` library
- Comment-based annotation systems
- Code generation patterns
- Macro-like transformations in a functional language

The implementation is intentionally simple and serves as a foundation for understanding how such systems might work.

## Development

```sh
gleam run   # Run the macro processor
gleam test  # Run the tests
```

Further documentation can be found at <https://hexdocs.pm/miracles>.
