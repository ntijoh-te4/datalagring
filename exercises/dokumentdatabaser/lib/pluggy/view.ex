defmodule Pluggy.View do
  @moduledoc """
  Tunn render-hjälpare: kör en EEx-mall ur `priv/templates/`
  och stoppar in resultatet i `layout.html.eex`.
  """

  def render(template, assigns \\ []) do
    inner = EEx.eval_file(path(template), assigns: assigns)
    EEx.eval_file(path("layout.html.eex"), assigns: [inner: inner])
  end

  defp path(template) do
    Path.join([:code.priv_dir(:pluggy), "templates", template])
  end
end
