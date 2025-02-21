defmodule ExWebTools.SEO do
  @moduledoc false
  alias Phoenix.LiveView.Socket
  alias ExWebTools.PageLink
  alias ExWebTools.PageMeta

  @site_name Application.compile_env!(:ex_web_tools, :name)
  @site_url Application.compile_env!(:ex_web_tools, :url)
  @site_logo_url Application.compile_env!(:ex_web_tools, :logo_url)
  @site_description Application.compile_env!(:ex_web_tools, :description)
  @site_social_media_links Application.compile_env!(:ex_web_tools, :social_media_links)
  @site_author Application.compile_env!(:ex_web_tools, :author)

  def build_meta(conn_or_socket, options \\ []) do
    defaults = [
      title: "",
      description: nil,
      image: nil,
      breadcrumbs: [],
      article: nil
    ]

    options = options |> Keyword.validate!(defaults) |> Map.new()

    metas =
      List.flatten([
        build_page_seo(conn_or_socket, options.title, options.description, options.image),
        build_open_graph(conn_or_socket, options.title, options.description, options.image)
      ])

    schemas =
      [
        build_website_schema(),
        build_org_schema()
      ]

    links = List.flatten([build_page_links(conn_or_socket)])

    {schemas, breadcrumbs} =
      if Enum.empty?(options.breadcrumbs) do
        {schemas, []}
      else
        schemas = schemas ++ build_breadcrumb_schema(options.breadcrumbs)
        {schemas, options.breadcrumbs}
      end

    schemas =
      if is_nil(options.article) do
        schemas
      else
        schemas ++ build_article_schema(options.article)
      end

    schemas = List.flatten(schemas)

    assign(conn_or_socket, :meta, %{
      page_title: options.title,
      breadcrumbs: breadcrumbs,
      links: links,
      metas: metas,
      schemas: schemas
    })
  end

  defp build_page_seo(_conn_or_socket, title, description, image) do
    Enum.reject(
      [
        new_page_meta("title", build_page_title(title)),
        new_page_meta("description", description |> strip_html_tags() |> truncate()),
        new_page_meta("image", image)
      ],
      &is_nil(&1.content)
    )
  end

  defp build_page_links(conn_or_socket) do
    Enum.reject([new_page_link("canonical", get_current_url(conn_or_socket))], &is_nil(&1.href))
  end

  defp build_open_graph(conn_or_socket, title, description, image) do
    Enum.reject(
      [
        new_page_meta("og:title", build_page_title(title)),
        new_page_meta("og:type", "website"),
        new_page_meta("og:locale", "sv_SE"),
        new_page_meta("og:description", description |> strip_html_tags() |> truncate()),
        new_page_meta("og:url", get_current_url(conn_or_socket)),
        new_page_meta("og:image", image)
      ],
      &is_nil(&1.content)
    )
  end

  defp build_website_schema do
    [
      %{
        "@context" => "https://schema.org/",
        "@type" => "WebSite",
        "name" => @site_name,
        "url" => @site_url
      }
    ]
  end

  defp build_org_schema do
    [
      %{
        "@context" => "https://schema.org/",
        "@type" => "Organization",
        "name" => @site_name,
        "url" => @site_url,
        "logo" => @site_logo_url,
        "description" => @site_description,
        "sameAs" => @site_social_media_links
      }
    ]
  end

  defp build_breadcrumb_schema(breadcrumbs) when is_list(breadcrumbs) do
    base_url = @site_url

    [
      %{
        "@context" => "https://schema.org",
        "@type" => "BreadcrumbList",
        "itemListElement" =>
          breadcrumbs
          |> Enum.with_index(1)
          |> Enum.map(fn {breadcrumb, index} ->
            %{
              "@type" => "ListItem",
              "position" => index,
              "name" => breadcrumb[:label],
              "item" => base_url |> URI.merge(breadcrumb[:to]) |> URI.to_string()
            }
          end)
      }
    ]
  end

  def build_article_schema(article) do
    [
      %{
        "@context" => "https://schema.org",
        "@type" => "Article",
        "headline" => article.title,
        "description" => article.description,
        "image" => article.image,
        "datePublished" => article.inserted_at,
        "mainEntityOfPage" => %{
          "@type" => "WebPage",
          # Replace with the actual URL of the article if needed
          "@id" => "#{@site_url}/#{article.slug}"
        },
        "author" => %{
          "@type" => "Person",
          "name" => @site_author
        },
        "publisher" => %{
          "@type" => "Organization",
          "name" => @site_name,
          "logo" => %{
            "@type" => "ImageObject",
            "url" => @site_logo_url
          }
        }
      }
    ]
  end

  defp build_page_title(title) when title in [nil, ""] do
    @site_name
  end

  defp build_page_title(title) do
    "#{title} - #{@site_name}"
  end

  defp assign(%Socket{} = conn_or_socket, key, value) do
    Phoenix.Component.assign(conn_or_socket, key, value)
  end

  defp assign(conn_or_socket, key, value) do
    Plug.Conn.assign(conn_or_socket, key, value)
  end

  defp get_current_url(%Socket{} = conn_or_socket) do
    base_url = @site_url

    if conn_or_socket.assigns[:current_uri] do
      base_url
      |> URI.merge(conn_or_socket.assigns.current_uri.path)
      |> URI.to_string()

      # URI.to_string(%{conn_or_socket.assigns.current_uri | query: nil})
    else
      ""
    end
  end

  defp get_current_url(conn_or_socket) do
    base_url = @site_url
    current = URI.parse(Phoenix.Controller.current_url(conn_or_socket, %{}))

    base_url
    |> URI.merge(current.path)
    |> URI.to_string()
  end

  defp new_page_meta(name, content) do
    %PageMeta{name: name, content: content}
  end

  defp new_page_link(rel, href) do
    %PageLink{rel: rel, href: href}
  end

  @spec truncate(String.t()) :: String.t()
  def truncate(string) do
    truncate(string, 40)
  end

  def truncate(nil, _) do
    nil
  end

  @spec truncate(String.t(), integer()) :: String.t()
  def truncate(string, max_length, trail \\ "..") do
    if String.length(string) > max_length do
      "#{String.slice(string, 0, max_length)}#{trail}"
    else
      string
    end
  end

  defp strip_html_tags(nil) do
    nil
  end

  defp strip_html_tags(string) when is_binary(string) do
    Regex.replace(~r/<[^>]*>/, string, "")
  end
end
