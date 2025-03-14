defmodule ExWebTools.PageMeta do
  @moduledoc """
  A struct representing HTML meta tags for SEO purposes.

  This struct is used by the `ExWebTools.SEO` module to generate the necessary
  meta tags for your pages and is consumed by the `ExWebTools.Components.Head`
  component.

  ## Fields

  * `:name` - The name/property of the meta tag
  * `:content` - The content value of the meta tag
  """
  defstruct name: nil,
            content: nil
end
