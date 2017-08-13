ExUnit.start()

# Source: https://gist.github.com/henrik/1054546364ac68da4102
defmodule CompileTimeAssertions do
  defmacro assert_compile_time_raise(exception, message, quoted_code) do
    quote do
      assert_raise unquote(exception), unquote(message), fn ->
        Code.eval_quoted(unquote(quoted_code))
      end
    end
  end
end
