defmodule Marcus do
  @moduledoc """
  A library for writing interactive CLIs.

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

  ## Disabling `stderr`

  Errors are printed on `stderr` by default, but sometimes you may want to use
  `stdout` instead. You can do so by adding to your configuration:

      config :marcus, stderr: false
  """

  alias IO.ANSI

  @typedoc "Answer to a yes/no question"
  @type yesno() :: :yes | :no | nil

  @yes ~w(y Y yes YES Yes)
  @no ~w(n N no NO No)

  @doc """
  Enables ANSI colors.
  """
  @spec enable_colors :: :ok
  def enable_colors do
    Application.put_env(:elixir, :ansi_enabled, true)
  end

  @doc """
  Prints the given ANSI-formatted `message`.
  """
  @spec info(ANSI.ansidata()) :: :ok
  def info(message) do
    message |> ANSI.format() |> IO.puts()
  end

  @doc """
  Prints the given ANSI-formatted `message` in bright blue.
  """
  @spec notice(ANSI.ansidata()) :: :ok
  def notice(message) do
    info([:blue, :bright, message])
  end

  @doc """
  Prints the given ANSI-formatted `message` in bright green.
  """
  @spec success(ANSI.ansidata()) :: :ok
  def success(message) do
    info([:green, :bright, message])
  end

  @doc """
  Prints the given ANSI-formatted `message` in green.
  """
  @spec green_info(ANSI.ansidata()) :: :ok
  def green_info(message) do
    info([:green, message])
  end

  @doc """
  Prints the given ANSI-formatted error `message` on `:stderr`.
  """
  @spec error(ANSI.ansidata()) :: :ok
  def error(message) do
    device =
      if Application.get_env(:marcus, :stderr, true),
        do: :stderr,
        else: :stdio

    IO.puts(device, ANSI.format([:red, :bright, message]))
  end

  @doc """
  Prints the given ANSI-formatter error an exits with an error status.
  """
  @spec halt(ANSI.ansidata()) :: no_return()
  @spec halt(ANSI.ansidata(), non_neg_integer()) :: no_return()
  def halt(message, status \\ 1) do
    error(message)
    System.halt(status)
  end

  @doc """
  Prints the given `message` and prompts the user for input.

  The result string is trimmed.

  ## Options

    * `default` - default value for empty replies (printed in the prompt if set)
    * `required` - wether a non-empty input is required (default: `false`)
    * `error_message` - the message to print if a required input is missing
    * `length` - the range of acceptable string length

  ## Examples

      prompt_string("GitHub account")
      # Name: ejpcmac
      # => "ejpcmac"

      prompt_string("Hello", default: "world")
      # Hello [world]:
      # => "world"

      prompt_string("Name", required: true)
      # Name:
      # You must provide a value!

      prompt_string("Name", required: true, error_message: "Please provide a name.")
      # Name:
      # Please provide a name.

      prompt_string("Nick", length: 3..20)
      # Nick (3-20 characters): me
      # The value must be 3 to 20 characters
      #
      # Nick (3-20 characters): my_nick
      # => "my_nick"
  """
  @spec prompt_string(String.t()) :: String.t()
  @spec prompt_string(String.t(), keyword()) :: String.t()
  def prompt_string(message, opts \\ []) do
    (message <> format_length(opts[:length]) <> format_default(opts[:default]))
    |> IO.gets()
    |> IO.iodata_to_binary()
    |> String.trim()
    |> parse_response(opts[:default], !!opts[:required])
    |> case do
      nil ->
        error_message = opts[:error_message] || "You must provide a value!"
        error(error_message <> "\n")
        prompt_string(message, opts)

      value ->
        if valid_length?(value, opts[:length]) do
          value
        else
          min..max = opts[:length]
          error("The value must be #{min} to #{max} characters long.\n")
          prompt_string(message, opts)
        end
    end
  end

  @spec format_length(Range.t() | nil) :: String.t()
  defp format_length(nil), do: ""
  defp format_length(min..max), do: " (#{min}-#{max} characters)"

  @spec format_default(String.t() | nil) :: String.t()
  defp format_default(nil), do: ": "
  defp format_default(default), do: " [#{default}]: "

  @spec parse_response(String.t(), String.t() | nil, boolean()) ::
          String.t() | nil
  defp parse_response("", nil, true), do: nil
  defp parse_response("", default, _) when not is_nil(default), do: default
  defp parse_response(value, _default, _), do: value

  @spec valid_length?(String.t(), Range.t() | nil) :: boolean()
  defp valid_length?(_value, nil), do: true
  defp valid_length?(value, min..max), do: String.length(value) in min..max

  @doc """
  Prints the given `message` and prompts the user for an integer.

  ## Options

    * `default` - default value for empty replies (printed in the prompt if set)
    * `range` - the acceptable range

  ## Examples

      prompt_integer("Age")
      # Age: 24
      # => 24

      prompt_integer("Integer")
      # Integer: Hello
      # The value must be an integer.

      prompt_integer("Current level", default: 1)
      # Current level [1]:
      # => 1

      prompt_integer("Percentage", range: 0..100)
      # Percentage (0-100): 200
      # The value must be between 0 and 100.
  """
  @spec prompt_integer(String.t()) :: integer()
  @spec prompt_integer(String.t(), keyword()) :: integer()
  def prompt_integer(message, opts \\ []) do
    default = if opts[:default], do: opts[:default] |> Integer.to_string()

    (message <> format_range(opts[:range]))
    |> prompt_string(default: default, required: true)
    |> Integer.parse()
    |> case do
      {choice, ""} ->
        if in_range?(choice, opts[:range]) do
          choice
        else
          min..max = opts[:range]
          error("The value must be between #{min} and #{max}.\n")
          prompt_integer(message, opts)
        end

      _ ->
        error("The value must be an integer.\n")
        prompt_integer(message, opts)
    end
  end

  @spec format_range(Range.t() | nil) :: String.t()
  defp format_range(nil), do: ""
  defp format_range(min..max), do: " (#{min}-#{max})"

  @spec in_range?(integer(), Range.t() | nil) :: boolean()
  defp in_range?(_value, nil), do: true
  defp in_range?(value, min..max), do: value in min..max

  @doc """
  Asks the user a yes/no `question`.

  If there is no default value, the user must type an answer. Otherwise hitting
  enter chooses the default answer.

  ## Options

    * `default` - default value for empty replies (`:yes` or `:no`, hilighted in
        the prompt if set)

  ## Examples

      yes?("Continue?")
      # Continue? (y/n)
      # You must answer yes or no.
      #
      # Continue? (y/n) y
      # => true

      yes?("Is it good?", default: :yes)
      # Is it good? [Y/n]
      # => true

      yes?("No?", default: :no)
      # No? [y/N]
      # => false
  """
  @spec yes?(String.t()) :: boolean()
  @spec yes?(String.t(), keyword()) :: boolean()
  def yes?(message, opts \\ []) do
    (message <> format_yesno(opts[:default]))
    |> IO.gets()
    |> IO.iodata_to_binary()
    |> String.trim()
    |> parse_yesno(opts[:default])
    |> case do
      nil ->
        error("You must answer yes or no.\n")
        yes?(message, opts)

      answer ->
        answer == :yes
    end
  end

  @spec format_yesno(yesno()) :: String.t()
  defp format_yesno(:yes), do: " [Y/n] "
  defp format_yesno(:no), do: " [y/N] "
  defp format_yesno(nil), do: " (y/n) "

  @spec parse_yesno(String.t(), yesno()) :: yesno()
  defp parse_yesno(value, _default) when value in @yes, do: :yes
  defp parse_yesno(value, _default) when value in @no, do: :no
  defp parse_yesno("", default), do: default
  defp parse_yesno(_, _default), do: nil

  @doc """
  Asks the user to choose between a list of elements.

  The given `list` must be a keyword list. The values will be printed and the
  key of the chosen one returned.

  ## Options

    * `default` - default key for empty replies (printed in the prompt if set)

  ## Examples

      choose("What do you want?",
        tea: "A cup of tea",
        coffee: "Some coffee",
        other: "Something else"
      )
      # What do you want?
      #
      #   1. A cup of tea
      #   2. Some coffee
      #   3. Something else
      #
      # Choice: 4
      # The choice must be an integer between 1 and 3.
      #
      # Choice: 3
      # => :other

      choose("Please make a choice:", [good: "The good choice"], default: :good)
      # Please make a choice:
      #
      #   1. The good choice
      #
      # Choice [1]:
      # => :good
  """
  @spec choose(String.t(), keyword()) :: atom()
  @spec choose(String.t(), keyword(), keyword()) :: atom()
  def choose(message, [_ | _] = list, opts \\ []) do
    info(message <> "\n")

    list
    |> Keyword.values()
    |> Enum.with_index(1)
    |> Enum.each(fn {elem, i} -> IO.puts("  #{i}. #{elem}") end)

    info("")

    default_index =
      with v when not is_nil(v) <- opts[:default],
           i when not is_nil(i) <- Enum.find_index(list, &(elem(&1, 0) == v)),
           do: Integer.to_string(i + 1)

    index = list |> length() |> get_choice(default_index)

    list
    |> Enum.at(index - 1)
    |> elem(0)
  end

  @spec get_choice(pos_integer(), pos_integer() | nil) :: pos_integer()
  defp get_choice(max, default) do
    "Choice"
    |> prompt_string(
      default: default,
      required: true,
      error_message: "You must make a choice!"
    )
    |> Integer.parse()
    |> case do
      {choice, ""} when choice in 1..max ->
        choice

      _ ->
        error("The choice must be an integer between 1 and #{max}.\n")
        get_choice(max, default)
    end
  end
end
