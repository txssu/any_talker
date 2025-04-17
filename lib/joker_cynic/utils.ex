defmodule JokerCynic.Utils do
  @moduledoc false

  @spec get_env_and_transform(String.t(), (String.t() -> result)) :: result
        when result: any()
  def get_env_and_transform(name, transformer) do
    if value = System.get_env(name) do
      transformer.(value)
    end
  end
end
