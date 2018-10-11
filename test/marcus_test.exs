defmodule MarcusTest do
  use ExUnit.Case
  use ExUnitProperties

  import ExUnit.CaptureIO
  import Marcus

  alias IO.ANSI

  describe "info/1" do
    property "prints the given message" do
      check all message <- string(:printable) do
        assert capture_io(fn -> info(message) end) == message <> "\n"
      end
    end

    property "formats the message" do
      check all message <- string(:printable) do
        assert capture_io(fn -> info([:red, message]) end) ==
                 ANSI.red() <> message <> ANSI.reset() <> "\n"
      end
    end
  end

  describe "green_info/1" do
    property "prints the given message in green" do
      check all message <- string(:printable) do
        assert capture_io(fn -> green_info(message) end) ==
                 ANSI.green() <> message <> ANSI.reset() <> "\n"
      end
    end
  end

  describe "error/1" do
    property "prints the given message in bright red on stderr" do
      check all message <- string(:printable) do
        assert capture_io(:stderr, fn -> error(message) end) ==
                 ANSI.red() <> ANSI.bright() <> message <> ANSI.reset() <> "\n"
      end
    end

    property "formats the message" do
      check all message <- string(:printable) do
        assert capture_io(:stderr, fn -> error([:blue, message]) end) ==
                 ANSI.red() <>
                   ANSI.bright() <>
                   ANSI.blue() <> message <> ANSI.reset() <> "\n"
      end
    end
  end

  describe "halt/2" do
    # Non-testable (calls to System.halt/1)
  end

  describe "prompt_string/2" do
    ## Standart cases

    property "prints the given message and prompts for an input" do
      check all message <- string(:printable) do
        assert capture_io("\n", fn -> prompt_string(message) end) ==
                 message <> ": "
      end
    end

    property "adds the default value to the prompt" do
      check all message <- string(:printable),
                default <- string(:printable) do
        assert capture_io("\n", fn ->
                 prompt_string(message, default: default)
               end) == "#{message} [#{default}]: "
      end
    end

    property "adds the length range to the prompt" do
      check all message <- string(:printable),
                min <- integer(1..50),
                max <- integer((min + 1)..100),
                input <- string(:alphanumeric, length: min) do
        assert capture_io(input <> "\n", fn ->
                 prompt_string(message, length: min..max)
               end) == "#{message} (#{min}-#{max} characters): "
      end
    end

    property "returns the user input" do
      check all input <- string(:printable, min_length: 1) do
        capture_io(input <> "\n", fn ->
          assert prompt_string("") == input
        end)
      end
    end

    test "accepts empty inputs by default" do
      capture_io("\n", fn ->
        assert prompt_string("") == ""
      end)
    end

    property "returns the default value on empty inputs" do
      check all default <- string(:printable) do
        capture_io("\n", fn ->
          assert prompt_string("", default: default) == default
        end)
      end
    end

    property "returns the user input if it is not empty when there is a default
              value" do
      check all default <- string(:printable),
                input <- string(:printable, min_length: 1) do
        capture_io(input <> "\n", fn ->
          assert prompt_string("", default: default) == input
        end)
      end
    end

    ## Errors

    test "prints an error message and keep asking on empty inputs when
              `required: true` is set" do
      capture_io("\n.\n", fn ->
        assert capture_io(:stderr, fn ->
                 prompt_string("", required: true)
               end) ==
                 ANSI.red() <>
                   ANSI.bright() <>
                   "You must provide a value!\n" <> ANSI.reset() <> "\n"
      end)
    end

    property "prints a custom error message if set" do
      check all error_message <- string(:printable) do
        capture_io("\n.\n", fn ->
          assert capture_io(:stderr, fn ->
                   prompt_string("",
                     required: true,
                     error_message: error_message
                   )
                 end) ==
                   ANSI.red() <>
                     ANSI.bright() <>
                     error_message <> "\n" <> ANSI.reset() <> "\n"
        end)
      end
    end

    property "prints an error message an keep asking if the input length is not
              in the range" do
      check all min <- integer(1..50),
                max <- integer((min + 1)..100),
                input <- string(:alphanumeric, length: min) do
        capture_io("\n" <> input <> "\n", fn ->
          assert capture_io(:stderr, fn ->
                   prompt_string("", length: min..max)
                 end) ==
                   ANSI.red() <>
                     ANSI.bright() <>
                     "The value must be #{min} to #{max} characters long.\n" <>
                     ANSI.reset() <> "\n"
        end)
      end
    end
  end

  describe "prompt_integer/2" do
    ## Standard cases

    property "prints the given message and prompts for an input" do
      check all message <- string(:printable) do
        assert capture_io("0\n", fn -> prompt_integer(message) end) ==
                 message <> ": "
      end
    end

    property "adds the default value to the prompt" do
      check all message <- string(:printable),
                default <- integer() do
        assert capture_io("0\n", fn ->
                 prompt_integer(message, default: default)
               end) == "#{message} [#{default}]: "
      end
    end

    property "adds the valid range to the prompt" do
      check all message <- string(:printable),
                min <- integer(0..500),
                max <- integer((min + 1)..1000),
                input <- integer(min..max) do
        assert capture_io("#{input}\n", fn ->
                 prompt_integer(message, range: min..max)
               end) == "#{message} (#{min}-#{max}): "
      end
    end

    property "returns the user input as an integer" do
      check all input <- integer() do
        capture_io("#{input}\n", fn ->
          assert prompt_integer("") == input
        end)
      end
    end

    property "returns the default value on empty inputs" do
      check all default <- integer() do
        capture_io("\n", fn ->
          assert prompt_integer("", default: default) == default
        end)
      end
    end

    property "returns the user input if it is not empty when there is a default
              value" do
      check all default <- integer(),
                input <- integer(),
                input != default do
        capture_io("#{input}\n", fn ->
          assert prompt_integer("", default: default) == input
        end)
      end
    end

    ## Errors

    test "prints an error message and keeps asking on empty inputs when
              there is no default value" do
      capture_io("\n0\n", fn ->
        assert capture_io(:stderr, fn -> prompt_integer("") end) ==
                 ANSI.red() <>
                   ANSI.bright() <>
                   "You must provide a value!\n" <> ANSI.reset() <> "\n"
      end)
    end

    test "prints an error message and keeps asking if the input is not an
              integer" do
      capture_io("Value\n0\n", fn ->
        assert capture_io(:stderr, fn -> prompt_integer("") end) ==
                 ANSI.red() <>
                   ANSI.bright() <>
                   "The value must be an integer.\n" <> ANSI.reset() <> "\n"
      end)
    end

    property "prints an error message and keeps asking if the input is not in
              range" do
      check all min <- integer(1..500),
                max <- integer((min + 1)..1000),
                input <- integer(min..max) do
        capture_io("0\n#{input}\n", fn ->
          assert capture_io(:stderr, fn ->
                   prompt_integer("", range: min..max)
                 end) ==
                   ANSI.red() <>
                     ANSI.bright() <>
                     "The value must be between #{min} and #{max}.\n" <>
                     ANSI.reset() <> "\n"
        end)
      end
    end
  end

  describe "yes?/2" do
    ## Standard cases

    property "prints the given message and prompts for an input" do
      check all message <- string(:printable) do
        assert capture_io("y\n", fn -> yes?(message) end) ==
                 message <> " (y/n) "
      end
    end

    property "hilights the default yes" do
      check all message <- string(:printable) do
        assert capture_io("\n", fn -> yes?(message, default: :yes) end) ==
                 message <> " [Y/n] "
      end
    end

    property "hilights the default no" do
      check all message <- string(:printable) do
        assert capture_io("\n", fn -> yes?(message, default: :no) end) ==
                 message <> " [y/N] "
      end
    end

    property "returns `true` for y, Y, yes, YES, Yes" do
      check all input <- member_of(~w(y Y yes YES Yes)) do
        capture_io(input <> "\n", fn ->
          assert yes?("") == true
        end)
      end
    end

    property "returns `false` for n, N, no, NO, No" do
      check all input <- member_of(~w(n N no NO No)) do
        capture_io(input <> "\n", fn ->
          assert yes?("") == false
        end)
      end
    end

    property "returns the default value on empty inputs" do
      check all default <- member_of([:yes, :no]) do
        capture_io("\n", fn ->
          assert yes?("", default: default) == (default == :yes)
        end)
      end
    end

    property "returns the user input if it is not empty when there is a default
              value" do
      check all default <- member_of([:yes, :no]),
                input <- member_of(~w(y n)) do
        capture_io(input <> "\n", fn ->
          assert yes?("", default: default) == (input == "y")
        end)
      end
    end

    ## Errors

    test "prints an error message and keeps asking on empty inputs when
              there is no default value" do
      capture_io("\ny\n", fn ->
        assert capture_io(:stderr, fn -> yes?("") end) ==
                 ANSI.red() <>
                   ANSI.bright() <>
                   "You must answer yes or no.\n" <> ANSI.reset() <> "\n"
      end)
    end

    property "prints an error message and keeps asking on invalid inputs" do
      check all invalid <- string(:printable),
                invalid not in ~w(y Y yes YES Yes n N no NO No) do
        capture_io(invalid <> "\ny\n", fn ->
          assert capture_io(:stderr, fn -> yes?("") end) ==
                   ANSI.red() <>
                     ANSI.bright() <>
                     "You must answer yes or no.\n" <> ANSI.reset() <> "\n"
        end)
      end
    end
  end

  # Choice list generator.
  defp choice_list,
    do: list_of({atom(:alphanumeric), string(:printable)}, min_length: 1)

  # Formats the choices as expected.
  defp format_choices(choices) do
    choices
    |> Keyword.values()
    |> Enum.with_index(1)
    |> Enum.map(fn {choice, i} -> "  #{i}. #{choice}\n" end)
    |> Enum.join()
  end

  describe "choose/3" do
    ## Standard cases

    property "prints the given message and list of options, and prompts the user
              for a choice" do
      check all message <- string(:printable),
                choices <- choice_list() do
        assert capture_io("1\n", fn -> choose(message, choices) end) ==
                 message <> "\n\n" <> format_choices(choices) <> "\nChoice: "
      end
    end

    property "adds the default value to the choice prompt" do
      check all message <- string(:printable),
                choices <- choice_list(),
                default <- member_of(Keyword.keys(choices)) do
        default_index =
          choices
          |> Enum.find_index(&(elem(&1, 0) == default))
          |> Kernel.+(1)
          |> Integer.to_string()

        assert capture_io("1\n", fn ->
                 choose(message, choices, default: default)
               end) ==
                 message <>
                   "\n\n" <>
                   format_choices(choices) <> "\nChoice [#{default_index}]: "
      end
    end

    property "returns the user choice" do
      check all message <- string(:printable),
                choices <- choice_list(),
                input <- integer(1..length(choices)) do
        capture_io("#{input}\n", fn ->
          assert choose(message, choices) ==
                   choices |> Enum.at(input - 1) |> elem(0)
        end)
      end
    end

    property "returns the default value on empty inputs" do
      check all message <- string(:printable),
                choices <- choice_list(),
                default <- member_of(Keyword.keys(choices)) do
        capture_io("\n", fn ->
          assert choose(message, choices, default: default) == default
        end)
      end
    end

    property "returns the user choice if it is not empty when there is a default
              value" do
      check all message <- string(:printable),
                choices <- choice_list(),
                default <- member_of(Keyword.keys(choices)),
                input <- integer(1..length(choices)) do
        capture_io("#{input}\n", fn ->
          assert choose(message, choices, default: default) ==
                   choices |> Enum.at(input - 1) |> elem(0)
        end)
      end
    end

    ## Errors

    test "does not accept empty lists of choices" do
      assert_raise FunctionClauseError, fn -> choose("", []) end
    end

    test "prints an error message and keeps asking on empty choices when
              there is no default value" do
      capture_io("\n1\n", fn ->
        assert capture_io(:stderr, fn -> choose("", a: "a") end) ==
                 ANSI.red() <>
                   ANSI.bright() <>
                   "You must make a choice!\n" <> ANSI.reset() <> "\n"
      end)
    end

    test "prints an error message and keeps asking on invalid choices" do
      capture_io("3\n1", fn ->
        assert capture_io(:stderr, fn -> choose("", a: "a", b: "b") end) ==
                 ANSI.red() <>
                   ANSI.bright() <>
                   "The choice must be an integer between 1 and 2.\n" <>
                   ANSI.reset() <> "\n"
      end)
    end
  end
end
