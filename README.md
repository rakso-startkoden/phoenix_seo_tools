# PhoenixSEOTools

PhoenixSEOTools is a lightweight Elixir library for Phoenix and Phoenix LiveView applications that helps you build SEO-optimized websites with minimal configuration. It generates and manages meta tags, Open Graph tags, JSON-LD schemas, and canonical links to improve your site's search engine visibility and social media presentation.

## Features

- Automatic generation of SEO meta tags (title, description, image)
- Open Graph tags for better social media sharing
- JSON-LD structured data for search engines (Organization, Website, Article, BreadcrumbList)
- Canonical URL management
- Simple integration with Phoenix and Phoenix LiveView
- Customizable for any website

## Installation

Add `phoenix_seo_tools` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_seo_tools, "~> 0.0.1"}
  ]
end
```

## Configuration

Add required configuration to your application's config:

```elixir
# In config/config.exs
config :phoenix_seo_tools,
  name: "My Site Name",
  url: "https://yourdomain.com",
  logo_url: "https://yourdomain.com/images/logo.png",
  description: "My site description",
  social_media_links: [
    twitter: "https://twitter.com/yourhandle",
    facebook: "https://facebook.com/yourpage"
  ],
  author: "My Name"
```

## Usage

### In Controllers

```elixir
defmodule MyAppWeb.PageController do
  use MyAppWeb, :controller
  
  def show(conn, %{"slug" => slug}) do
    # Fetch your page data
    page = Pages.get_by_slug!(slug)
    
    # Add SEO metadata
    conn
    |> PhoenixSEOTools.SEO.build_meta(
      title: page.title,
      description: page.description,
      image: page.hero_url,
      breadcrumbs: [
        %{label: "Home", to: "/"},
        %{label: "Pages", to: "/pages"},
        %{label: page.title, to: "/pages/#{page.slug}"}
      ]
    )
    |> render(:show, page: page)
  end
end
```

### In LiveViews

```elixir
defmodule MyAppWeb.ArticleLive do
  use MyAppWeb, :live_view
  
  def mount(%{"slug" => slug}, _session, socket) do
    article = Articles.get_by_slug!(slug)
    
    # Add SEO metadata
    socket = PhoenixSEOTools.SEO.build_meta(socket,
      title: article.title,
      description: article.summary,
      image: article.cover_image_url,
      article: %{
        title: article.title,
        description: article.summary,
        image: article.cover_image_url,
        inserted_at: article.published_at,
        slug: article.slug
      }
    )
    
    {:ok, assign(socket, article: article)}
  end
end
```

### In your layout

Add the meta component to your `<head>` tag inside root layout:


### In lib/your_app_web/components/layouts/root.html.heex
```diff
<head>
-  <.live_title default="Placeholder" suffix=" · Phoenix Framework">
-    {assigns[:page_title]}
-  </.live_title>
+  <PhoenixSEOTools.Components.Head.meta meta={@meta} page_title={assigns[:page_title]} />
</head>
```


## Documentation

Complete documentation is available at [https://hexdocs.pm/phoenix_seo_tools](https://hexdocs.pm/phoenix_seo_tools).

## License

MIT License. See LICENSE file for details.

