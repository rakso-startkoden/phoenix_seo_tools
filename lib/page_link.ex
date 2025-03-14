defmodule ExWebTools.PageLink do
  @moduledoc """
  A struct representing HTML link tags for SEO purposes.

  This struct is used by the `ExWebTools.SEO` module to generate the necessary
  link tags (like canonical URLs) for your pages and is consumed by the 
  `ExWebTools.Components.Head` component.

  ## Fields

  * `:rel` - The relationship of the link (e.g., "canonical")
  * `:href` - The URL that the link points to
  """
  defstruct rel: nil,
            href: nil
end
