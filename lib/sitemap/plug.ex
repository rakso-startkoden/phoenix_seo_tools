defmodule PhoenixSEOTools.Sitemap.Plug do
  @moduledoc """
  A Plug that serves sitemap.xml files directly from your router.

  This allows you to serve a sitemap without creating a controller by using
  Phoenix's `forward` directive.

  ## Usage

  In your router:

  ```elixir
  forward "/sitemap.xml", PhoenixSEOTools.Sitemap.Plug, sitemap_module: MyAppWeb.Sitemap
  ```

  The sitemap module should implement the `PhoenixSEOTools.Sitemap` behaviour:

  ```elixir
  defmodule MyAppWeb.Sitemap do
    use PhoenixSEOTools.Sitemap

    @impl true
    def get_sitemap_urls do
      [
        %{loc: "https://example.com", priority: 1.0, changefreq: "daily"},
        %{loc: "https://example.com/about", priority: 0.8, changefreq: "monthly"}
      ]
    end
  end
  ```

  Note: When using `forward`, the path must be exact. If you use `forward "/sitemap.xml"`,
  the sitemap will be available at exactly `/sitemap.xml`, not at `/sitemap.xml/` or any sub-paths.
  """

  use Plug.Router
  alias PhoenixSEOTools.Sitemap

  plug :match
  plug :dispatch

  @doc false
  def init(opts) do
    sitemap_module = Keyword.fetch!(opts, :sitemap_module)
    
    unless Code.ensure_loaded?(sitemap_module) do
      raise ArgumentError, "Sitemap module #{inspect(sitemap_module)} is not available"
    end
    
    %{sitemap_module: sitemap_module}
  end

  @doc false
  def call(conn, %{sitemap_module: sitemap_module} = opts) do
    # Store the sitemap module in assigns for use in routes
    conn
    |> assign(:sitemap_module, sitemap_module)
    |> super(opts)
  end

  # Match root path - forward removes the prefix so we just match /
  get "/" do
    serve_sitemap(conn)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp serve_sitemap(conn) do
    sitemap_module = conn.assigns.sitemap_module
    urls = sitemap_module.get_sitemap_urls()
    xml = Sitemap.generate_xml(urls)
    
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end
end