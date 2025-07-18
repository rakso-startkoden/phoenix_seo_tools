defmodule PhoenixSEOTools.Sitemap.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PhoenixSEOTools.Sitemap.Plug, as: SitemapPlug

  defmodule TestSitemap do
    use PhoenixSEOTools.Sitemap

    @impl true
    def get_sitemap_urls do
      [
        %{loc: "https://test.com", priority: 1.0, changefreq: "daily"},
        %{loc: "https://test.com/about", priority: 0.8, changefreq: "monthly"}
      ]
    end
  end

  describe "init/1" do
    test "requires sitemap_module option" do
      assert_raise KeyError, ~r/key :sitemap_module not found/, fn ->
        SitemapPlug.init([])
      end
    end

    test "validates sitemap module exists" do
      assert_raise ArgumentError, ~r/Sitemap module NonExistent is not available/, fn ->
        SitemapPlug.init(sitemap_module: NonExistent)
      end
    end

    test "returns options with valid module" do
      assert %{sitemap_module: TestSitemap} = SitemapPlug.init(sitemap_module: TestSitemap)
    end
  end

  describe "serving sitemap" do
    setup do
      opts = SitemapPlug.init(sitemap_module: TestSitemap)
      {:ok, opts: opts}
    end

    test "serves sitemap at root path", %{opts: opts} do
      conn = 
        conn(:get, "/")
        |> SitemapPlug.call(opts)

      assert conn.status == 200
      assert {"content-type", "application/xml; charset=utf-8"} in conn.resp_headers
      assert conn.resp_body =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert conn.resp_body =~ "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
      assert conn.resp_body =~ "<loc>https://test.com</loc>"
      assert conn.resp_body =~ "<priority>1.0</priority>"
      assert conn.resp_body =~ "<changefreq>daily</changefreq>"
    end


    test "returns 404 for other paths", %{opts: opts} do
      conn = 
        conn(:get, "/other")
        |> SitemapPlug.call(opts)

      assert conn.status == 404
      assert conn.resp_body == "Not found"
    end

    test "returns 404 for POST requests", %{opts: opts} do
      conn = 
        conn(:post, "/")
        |> SitemapPlug.call(opts)

      assert conn.status == 404
    end
  end
end