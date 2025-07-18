defmodule PhoenixSEOToolsTest do
  use ExUnit.Case
  
  # Basic test to ensure the library loads
  test "library modules are available" do
    assert PhoenixSEOTools.SEO
    assert PhoenixSEOTools.Sitemap
  end
end
