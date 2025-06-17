defmodule AnyTalkerWeb.TelegramComponents do
  @moduledoc false
  use Phoenix.Component

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered

  attr :class, :string, default: nil

  slot :header
  slot :inner_block, required: true

  @spec section(map()) :: Rendered.t()
  def section(assigns) do
    ~H"""
    <section class={["bg-tg-bg p-[15px] rounded-xl", @class]}>
      <h2 :if={@header} class="text-center text-xl font-bold">
        {render_slot(@header)}
      </h2>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"

  @spec switch(map()) :: Rendered.t()
  def switch(%{field: %FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(field: nil, id: assigns.id || field.id)
      |> assign_new(:name, fn -> field.name end)
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", field.value)
      end)

    ~H"""
    <label class="tg-switch hover-effect flex cursor-pointer select-none items-center rounded-lg px-3">
      {@label}
      <input type="hidden" name={@name} value="false" />
      <div class="h-[42px] ml-auto flex items-center">
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="checkbox-field-input peer absolute h-0 w-0 opacity-0"
        />
        <div class="checkbox-toggle bg-[#707579] w-[1.9375rem] h-[0.875rem] rounded-[calc(1.9375rem/2)] mx-[3px] relative flex items-center">
          <div class="checkbox-toggle-circle border-[#707579] bg-tg-section-bg start-0 translate-x-[-3px] absolute h-5 w-5 rounded-full border-2">
          </div>
        </div>
      </div>
    </label>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, FormField

  @spec textarea(map()) :: Rendered.t()
  def textarea(%{field: %FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(field: nil, id: assigns.id || field.id)
      |> assign_new(:name, fn -> field.name end)
      |> assign_new(:value, fn -> field.value end)

    ~H"""
    <div class="px-3">
      <label for={@id}>{@label}</label>
      <textarea
        phx-update="ignore"
        id={@id}
        name={@name}
        class="min-h-[6rem] mx-[3px] mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6"
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}
      </textarea>
    </div>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text"

  attr :field, FormField

  @spec tg_input(map()) :: Rendered.t()
  def tg_input(%{field: %FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(field: nil, id: assigns.id || field.id)
      |> assign_new(:name, fn -> field.name end)
      |> assign_new(:value, fn -> field.value end)

    ~H"""
    <div class="px-3">
      <label for={@id}>{@label}</label>
      <input
        type={@type}
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class="mx-[3px] mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6"
      />
    </div>
    """
  end
end
