defmodule PhoenixSEOTools.SEO do
  @moduledoc """
  Core functionality for generating SEO-related metadata for your Phoenix application.

  This module provides functions to generate various SEO elements:
  - Basic meta tags (title, description, image)
  - Open Graph tags for social media sharing
  - JSON-LD structured data (Organization, Website, Article, BreadcrumbList)
  - Canonical URLs

  ## Configuration

  To use this module, add the following to your application config:

  ```elixir
  config :phoenix_seo_tools,
    name: "Your Site Name",
    url: "https://yourdomain.com",
    logo_url: "https://yourdomain.com/images/logo.png",
    description: "Your site description",
    social_media_links: [
      "https://twitter.com/yourhandle",
      "https://facebook.com/yourpage"
    ],
    author: "Your Name"
  ```
  """
  alias Phoenix.LiveView.Socket
  alias PhoenixSEOTools.PageLink
  alias PhoenixSEOTools.PageMeta

  @doc """
  Builds metadata for a page and assigns it to the connection or socket.

  This is the main function you'll use in your controllers or LiveViews to add SEO
  elements to your pages.

  ## Parameters

  * `conn_or_socket` - A Plug.Conn or Phoenix.LiveView.Socket
  * `options` - Keyword list of options:
    * `:title` - The page title (required)
    * `:description` - A description of the page (optional)
    * `:image` - URL to an image representing the page (optional)
    * `:breadcrumbs` - List of breadcrumb items (optional), each item should be a map with `:label` and `:to` keys
    * `:article` - Article details for blog posts or articles (optional)
    * `:schemas` - List of structured data schemas (optional) - see Structured Data section below

  ## Structured Data Schemas

  You can pass any schema.org structured data in the `:schemas` option. The library provides
  helper functions to build common schemas:

  ```elixir
  # Job posting example
  conn = PhoenixSEOTools.SEO.build_meta(conn,
    title: "Senior Developer Position",
    description: "We're hiring!",
    schemas: [
      PhoenixSEOTools.SEO.job_posting(
        title: "Senior Developer",
        description: "Job description",
        company_name: "Acme Corp",
        company_logo: "https://acme.com/logo.png",
        location: "Stockholm, Sweden",
        posted_date: ~D[2024-01-01],
        expiry_date: ~D[2024-12-31],
        company_url: "https://acme.com",
        employment_type: :full_time,
        application_url: "https://apply.com"
      )
    ]
  )

  # Job postings list example
  conn = PhoenixSEOTools.SEO.build_meta(conn,
    title: "Job Listings",
    schemas: [
      PhoenixSEOTools.SEO.job_postings_list([
        %{title: "Developer", url: "/jobs/developer", ...},
        %{title: "Designer", url: "/jobs/designer", ...}
      ])
    ]
  )
  ```

  ## Returns

  * A conn or socket with the `:meta` assign containing all generated metadata

  ## Examples

  ```elixir
  # In a controller:
  conn = PhoenixSEOTools.SEO.build_meta(conn, title: "Welcome", description: "Our homepage")

  # In a LiveView:
  socket = PhoenixSEOTools.SEO.build_meta(socket, 
    title: "Blog Post",
    description: "An interesting article",
    image: "https://example.com/images/post.jpg",
    breadcrumbs: [
      %{label: "Home", to: "/"},
      %{label: "Blog", to: "/blog"}
    ],
    article: %{
      title: "Blog Post",
      description: "An interesting article",
      image: "https://example.com/images/post.jpg",
      inserted_at: ~N[2023-01-01 12:00:00],
      slug: "blog-post"
    }
  )
  ```
  """
  def build_meta(conn_or_socket, options \\ []) do
    defaults = [
      title: Application.get_env(:phoenix_seo_tools, :name),
      description: Application.get_env(:phoenix_seo_tools, :description),
      image: Application.get_env(:phoenix_seo_tools, :logo_url),
      breadcrumbs: [],
      article: nil,
      schemas: [],
      site_name: Application.get_env(:phoenix_seo_tools, :name),
      site_url: Application.get_env(:phoenix_seo_tools, :url),
      site_logo_url: Application.get_env(:phoenix_seo_tools, :logo_url),
      site_description: Application.get_env(:phoenix_seo_tools, :description),
      site_social_media_links: Application.get_env(:phoenix_seo_tools, :social_media_links),
      site_author: Application.get_env(:phoenix_seo_tools, :author)
    ]

    options = options |> Keyword.validate!(defaults) |> Map.new()

    metas =
      List.flatten([
        build_page_seo(conn_or_socket, options),
        build_open_graph(conn_or_socket, options)
      ])

    schemas =
      [
        build_website_schema(options),
        build_org_schema(options)
      ]

    links = List.flatten([build_page_links(conn_or_socket, options)])

    {schemas, breadcrumbs} =
      if Enum.empty?(options.breadcrumbs) do
        {schemas, []}
      else
        schemas = schemas ++ build_breadcrumb_schema(options.breadcrumbs, options)
        {schemas, options.breadcrumbs}
      end

    schemas =
      if is_nil(options.article) do
        schemas
      else
        schemas ++ build_article_schema(options.article, options)
      end

    schemas = schemas ++ (options.schemas || [])

    schemas = List.flatten(schemas)

    assign(conn_or_socket, :meta, %{
      page_title: options.title,
      breadcrumbs: breadcrumbs,
      links: links,
      metas: metas,
      schemas: schemas
    })
  end

  defp build_page_seo(_conn_or_socket, options) do
    Enum.reject(
      [
        new_page_meta("title", build_page_title(options.title, options)),
        new_page_meta("description", options.description |> strip_html_tags() |> truncate()),
        new_page_meta("image", options.image)
      ],
      &is_nil(&1.content)
    )
  end

  defp build_page_links(conn_or_socket, options) do
    Enum.reject(
      [new_page_link("canonical", get_current_url(conn_or_socket, options))],
      &is_nil(&1.href)
    )
  end

  defp build_open_graph(conn_or_socket, options) do
    Enum.reject(
      [
        new_page_meta("og:title", build_page_title(options.title, options)),
        new_page_meta("og:type", "website"),
        new_page_meta("og:locale", "sv_SE"),
        new_page_meta("og:description", options.description |> strip_html_tags() |> truncate()),
        new_page_meta("og:url", get_current_url(conn_or_socket, options)),
        new_page_meta("og:image", options.image)
      ],
      &is_nil(&1.content)
    )
  end

  defp build_website_schema(options) do
    [
      %{
        "@context" => "https://schema.org/",
        "@type" => "WebSite",
        "name" => options.site_name,
        "url" => options.site_url
      }
    ]
  end

  defp build_org_schema(options) do
    [
      %{
        "@context" => "https://schema.org/",
        "@type" => "Organization",
        "name" => options.site_name,
        "url" => options.site_url,
        "logo" => options.site_logo_url,
        "description" => options.site_description,
        "sameAs" => Keyword.values(options.site_social_media_links)
      }
    ]
  end

  defp build_breadcrumb_schema(breadcrumbs, options) when is_list(breadcrumbs) do
    base_url = options.site_url

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

  def build_article_schema(article, options) do
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
          "@id" => "#{options.site_url}/#{article.slug}"
        },
        "author" => %{
          "@type" => "Person",
          "name" => options.site_author
        },
        "publisher" => %{
          "@type" => "Organization",
          "name" => options.site_name,
          "logo" => %{
            "@type" => "ImageObject",
            "url" => options.site_logo_url
          }
        }
      }
    ]
  end

  defp build_page_title(title, options) when title in [nil, ""] do
    options.site_name
  end

  defp build_page_title(title, options) do
    "#{title} - #{options.site_name}"
  end

  defp assign(%Socket{} = conn_or_socket, key, value) do
    Phoenix.Component.assign(conn_or_socket, key, value)
  end

  defp assign(conn_or_socket, key, value) do
    Plug.Conn.assign(conn_or_socket, key, value)
  end

  defp get_current_url(%Socket{} = conn_or_socket, options) do
    base_url = options.site_url

    if conn_or_socket.assigns[:current_uri] do
      base_url
      |> URI.merge(conn_or_socket.assigns.current_uri.path)
      |> URI.to_string()

      # URI.to_string(%{conn_or_socket.assigns.current_uri | query: nil})
    else
      ""
    end
  end

  defp get_current_url(conn_or_socket, options) do
    base_url = options.site_url
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

  @doc """
  Creates a JobPosting schema for structured data.
  
  ## Parameters
  
  * `opts` - Keyword list with the following keys:
    * `:title` - Job title (required)
    * `:description` - Job description (required)
    * `:company_name` - Name of the hiring company (required)
    * `:location` - Job location (required)
    * `:url` - URL to the job listing (required)
    * `:company_logo` - URL to company logo (optional)
    * `:company_url` - Company website URL (optional)
    * `:posted_date` - Date job was posted (optional)
    * `:expiry_date` - Job expiration date (optional)
    * `:employment_type` - One of `:full_time`, `:part_time`, `:contract`, `:temporary`, `:intern`, `:volunteer`, `:per_diem`, `:other` (optional, defaults to `:full_time`)
    * `:remote_allowed` - Boolean indicating if remote work is allowed (optional)
    * `:salary_min` - Minimum salary (optional)
    * `:salary_max` - Maximum salary (optional)
    * `:salary_currency` - Currency code like "USD" or "SEK" (optional)
    * `:application_url` - URL to apply (optional)
    * `:application_email` - Email to apply (optional)
  
  ## Examples
  
      iex> PhoenixSEOTools.SEO.job_posting(
      ...>   title: "Senior Elixir Developer",
      ...>   description: "We're looking for an experienced Elixir developer...",
      ...>   company_name: "Acme Corp",
      ...>   location: "Stockholm, Sweden",
      ...>   url: "https://example.com/jobs/senior-elixir-developer",
      ...>   posted_date: ~D[2024-01-01],
      ...>   employment_type: :full_time,
      ...>   salary_min: 50000,
      ...>   salary_max: 80000,
      ...>   salary_currency: "SEK"
      ...> )
  """
  def job_posting(opts) do
    required_keys = [:title, :description, :company_name, :location, :url]
    Enum.each(required_keys, fn key ->
      if is_nil(opts[key]) do
        raise ArgumentError, "#{key} is required for job_posting"
      end
    end)
    
    employment_type_map = %{
      full_time: "FULL_TIME",
      part_time: "PART_TIME",
      contract: "CONTRACT",
      temporary: "TEMPORARY",
      intern: "INTERN",
      volunteer: "VOLUNTEER",
      per_diem: "PER_DIEM",
      other: "OTHER"
    }
    
    schema = %{
      "@context" => "https://schema.org",
      "@type" => "JobPosting",
      "title" => opts[:title],
      "description" => strip_html_tags(opts[:description]),
      "url" => opts[:url],
      "hiringOrganization" => %{
        "@type" => "Organization",
        "name" => opts[:company_name]
      },
      "jobLocation" => %{
        "@type" => "Place",
        "address" => %{
          "@type" => "PostalAddress",
          "addressLocality" => opts[:location],
          "addressCountry" => opts[:country] || "SE"
        }
      }
    }
    
    # Add optional fields
    schema = if opts[:company_logo], do: put_in(schema["hiringOrganization"]["logo"], opts[:company_logo]), else: schema
    schema = if opts[:company_url], do: put_in(schema["hiringOrganization"]["sameAs"], opts[:company_url]), else: schema
    schema = if opts[:posted_date], do: Map.put(schema, "datePosted", format_date(opts[:posted_date])), else: schema
    schema = if opts[:expiry_date], do: Map.put(schema, "validThrough", format_date(opts[:expiry_date])), else: schema
    
    employment_type = Map.get(employment_type_map, opts[:employment_type] || :full_time, "FULL_TIME")
    schema = Map.put(schema, "employmentType", employment_type)
    
    # Add remote work option
    schema = if opts[:remote_allowed] do
      Map.put(schema, "jobLocationType", "TELECOMMUTE")
    else
      schema
    end
    
    # Add salary information
    schema = if opts[:salary_min] || opts[:salary_max] do
      base_salary = %{
        "@type" => "MonetaryAmount",
        "currency" => opts[:salary_currency] || "USD"
      }
      
      base_salary = if opts[:salary_min] && opts[:salary_max] do
        Map.merge(base_salary, %{
          "value" => %{
            "@type" => "QuantitativeValue",
            "minValue" => opts[:salary_min],
            "maxValue" => opts[:salary_max],
            "unitText" => "MONTH"
          }
        })
      else
        value = opts[:salary_min] || opts[:salary_max]
        Map.put(base_salary, "value", value)
      end
      
      Map.put(schema, "baseSalary", base_salary)
    else
      schema
    end
    
    # Add application information
    cond do
      opts[:application_url] ->
        Map.put(schema, "applicationContact", %{
          "@type" => "ContactPoint",
          "url" => opts[:application_url]
        })
      opts[:application_email] ->
        Map.put(schema, "applicationContact", %{
          "@type" => "ContactPoint",
          "email" => opts[:application_email]
        })
      true ->
        schema
    end
  end

  @doc """
  Creates an ItemList schema containing multiple job postings.
  
  ## Parameters
  
  * `job_postings` - List of job posting data, each item should have the same fields as `job_posting/1`
  
  ## Examples
  
      iex> PhoenixSEOTools.SEO.job_postings_list([
      ...>   %{title: "Developer", description: "...", company_name: "Acme", location: "Stockholm", url: "/jobs/1"},
      ...>   %{title: "Designer", description: "...", company_name: "Acme", location: "Stockholm", url: "/jobs/2"}
      ...> ])
  """
  def job_postings_list(job_postings) when is_list(job_postings) do
    %{
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "itemListElement" =>
        job_postings
        |> Enum.with_index(1)
        |> Enum.map(fn {job_data, index} ->
          # Ensure it has an @id if not already present
          item_schema = job_posting(job_data)
          item_schema = Map.put_new(item_schema, "@id", job_data[:url])
          
          %{
            "@type" => "ListItem",
            "position" => index,
            "item" => item_schema
          }
        end)
    }
  end

  defp format_date(nil), do: nil
  defp format_date(%Date{} = date), do: Date.to_iso8601(date)
  defp format_date(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp format_date(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
end
