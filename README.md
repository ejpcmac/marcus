# Marcus

[![hex.pm version](http://img.shields.io/hexpm/v/marcus.svg?style=flat)](https://hex.pm/packages/marcus)

Marcus is a library for writing interactive CLIs in Elixir.

## Features

Marcus provides helpers for:

* enabling ANSI colors,
* printing ANSI-formatted information,
* printing notices in bright blue,
* printing success messages in brigh green,
* printing information in green,
* printing errors (in bright red, on `stderr`)
* halting the VM with an error message and status.

You can also prompt the user for:

* a string,
* an integer,
* a yes/no question,
* a choice from a list.

## Examples

```elixir
import Marcus

prompt_string("Name")
# Name: Jean-Philippe
# => "Jean-Philippe"

prompt_integer("Integer")
# Integer: 8
# => 8

yes?("Do you want?")
# Do you want? (y/n) y
# => true

choose("Make a choice:", item1: "Item 1", item2: "Item 2")
# Make a choice:
#
#   1. Item 1
#   2. Item 2
#
# Choice: 2
# => :item2
```

## Setup

To use Marcus in your project, add this to your Mix dependencies:

```elixir
{:marcus, "~> 0.1.0"}
```

## [Contributing](CONTRIBUTING.md)

Before contributing to this project, please read the
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

Copyright © 2018 Jean-Philippe Cugnet

This project is licensed under the [MIT license](LICENSE).
