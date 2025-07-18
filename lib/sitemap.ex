defmodule PhoenixSEOTools.Sitemap do
  @moduledoc """
  Provides sitemap generation functionality for Phoenix applications.

  This module allows you to easily create XML sitemaps by implementing
  a simple behaviour that defines which URLs should be included.

  ## Usage with Forward (Recommended)

  The cleanest approach is to use Phoenix's `forward` directive with the provided Plug:

  ```elixir
  # In your router.ex
  forward "/sitemap.xml", PhoenixSEOTools.Sitemap.Plug, sitemap_module: MyAppWeb.Sitemap
  ```

  This serves the sitemap directly without needing a controller.

  ## Alternative: Direct Route

  You can also add it as a regular route:

  ```elixir
  # In your router.ex
  scope "/", MyAppWeb do
    pipe_through :browser
    
    get "/sitemap.xml", Sitemap, :render_sitemap
  end
  ```

  ## Creating Your Sitemap Module

  Either way, create your sitemap module:

  ```elixir
  defmodule MyAppWeb.Sitemap do
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
          lastmod: ~D[2024-01-01],
          changefreq: "monthly",
          priority: 0.8
        }
      ]
    end
  end
  ```

  ## Alternative: Using a Controller

  If you need more control, you can use a controller:

  ```elixir
  defmodule MyAppWeb.SitemapController do
    use MyAppWeb, :controller

    def index(conn, _params) do
      MyAppWeb.Sitemap.render_sitemap(conn)
    end
  end
  ```

  And add a route:

  ```elixir
  get "/sitemap.xml", SitemapController, :index
  ```
  """

  @doc """
  Returns a list of URLs to include in the sitemap.

  Each URL should be a map with the following keys:
  - `:loc` (required) - The URL location
  - `:lastmod` (optional) - Last modification date (Date, DateTime, or NaiveDateTime)
  - `:changefreq` (optional) - How frequently the page changes (daily, weekly, monthly, yearly)
  - `:priority` (optional) - Priority relative to other URLs on your site (0.0 to 1.0)
  """
  @callback get_sitemap_urls() :: [map()]

  defmacro __using__(_opts) do
    quote do
      @behaviour PhoenixSEOTools.Sitemap

      @doc """
      Renders the sitemap XML for the given connection.
      """
      def render_sitemap(conn) do
        urls = get_sitemap_urls()
        xml = PhoenixSEOTools.Sitemap.generate_xml(urls)

        conn
        |> Plug.Conn.put_resp_content_type("application/xml")
        |> Plug.Conn.send_resp(200, xml)
      end
    end
  end

  @doc """
  Generates the sitemap XML from a list of URL maps.
  """
  def generate_xml(urls) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.map_join(urls, "\n", &url_to_xml/1)}
    </urlset>
    """
  end

  defp url_to_xml(url) do
    loc = Map.fetch!(url, :loc)
    lastmod = format_lastmod(Map.get(url, :lastmod))
    changefreq = Map.get(url, :changefreq)
    priority = Map.get(url, :priority)

    parts = ["  <url>", "    <loc>#{escape_xml(loc)}</loc>"]
    
    parts = if lastmod, do: parts ++ ["    <lastmod>#{lastmod}</lastmod>"], else: parts
    parts = if changefreq, do: parts ++ ["    <changefreq>#{changefreq}</changefreq>"], else: parts
    parts = if priority, do: parts ++ ["    <priority>#{priority}</priority>"], else: parts
    
    parts = parts ++ ["  </url>"]
    
    Enum.join(parts, "\n")
  end

  defp format_lastmod(nil), do: nil
  defp format_lastmod(%Date{} = date), do: Date.to_iso8601(date)
  defp format_lastmod(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp format_lastmod(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)

  defp escape_xml(string) do
    string
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end