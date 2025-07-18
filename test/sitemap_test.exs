defmodule PhoenixSEOTools.SitemapTest do
  use ExUnit.Case

  defmodule TestSitemap do
    use PhoenixSEOTools.Sitemap

    @impl true
    def get_sitemap_urls do
      [
        %{
          loc: "https://example.com",
          lastmod: ~D[2024-01-01],
          changefreq: "daily",
          priority: 1.0
        },
        %{
          loc: "https://example.com/about",
          lastmod: ~D[2024-01-15],
          changefreq: "monthly",
          priority: 0.8
        },
        %{
          loc: "https://example.com/contact",
          changefreq: "yearly",
          priority: 0.5
        }
      ]
    end
  end

  describe "generate_xml/1" do
    test "generates valid sitemap XML" do
      urls = TestSitemap.get_sitemap_urls()
      xml = PhoenixSEOTools.Sitemap.generate_xml(urls)

      assert xml =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert xml =~ "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
      assert xml =~ "</urlset>"
    end

    test "includes all URL elements" do
      urls = TestSitemap.get_sitemap_urls()
      xml = PhoenixSEOTools.Sitemap.generate_xml(urls)

      # First URL with all elements
      assert xml =~ "<loc>https://example.com</loc>"
      assert xml =~ "<lastmod>2024-01-01</lastmod>"
      assert xml =~ "<changefreq>daily</changefreq>"
      assert xml =~ "<priority>1.0</priority>"

      # Second URL
      assert xml =~ "<loc>https://example.com/about</loc>"
      assert xml =~ "<lastmod>2024-01-15</lastmod>"
      assert xml =~ "<changefreq>monthly</changefreq>"
      assert xml =~ "<priority>0.8</priority>"

      # Third URL (without lastmod)
      assert xml =~ "<loc>https://example.com/contact</loc>"
      assert xml =~ "<changefreq>yearly</changefreq>"
      assert xml =~ "<priority>0.5</priority>"
    end

    test "escapes XML special characters" do
      urls = [
        %{
          loc: "https://example.com/page?foo=bar&baz=qux",
          changefreq: "daily"
        }
      ]

      xml = PhoenixSEOTools.Sitemap.generate_xml(urls)

      assert xml =~ "<loc>https://example.com/page?foo=bar&amp;baz=qux</loc>"
    end

    test "handles DateTime and NaiveDateTime" do
      urls = [
        %{
          loc: "https://example.com/1",
          lastmod: ~U[2024-01-01 12:00:00Z]
        },
        %{
          loc: "https://example.com/2",
          lastmod: ~N[2024-01-02 12:00:00]
        }
      ]

      xml = PhoenixSEOTools.Sitemap.generate_xml(urls)

      assert xml =~ "<lastmod>2024-01-01T12:00:00Z</lastmod>"
      assert xml =~ "<lastmod>2024-01-02T12:00:00</lastmod>"
    end
  end
end