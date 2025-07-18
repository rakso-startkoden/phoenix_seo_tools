defmodule PhoenixSEOTools.SEOTest do
  use ExUnit.Case
  alias PhoenixSEOTools.SEO

  describe "job_posting/1" do
    test "creates valid JobPosting schema with required fields" do
      schema = SEO.job_posting(
        title: "Senior Developer",
        description: "We need a developer",
        company_name: "Acme Corp",
        location: "Stockholm",
        url: "/jobs/senior-developer"
      )

      assert schema["@context"] == "https://schema.org"
      assert schema["@type"] == "JobPosting"
      assert schema["title"] == "Senior Developer"
      assert schema["description"] == "We need a developer"
      assert schema["url"] == "/jobs/senior-developer"
      assert schema["hiringOrganization"]["name"] == "Acme Corp"
      assert schema["jobLocation"]["address"]["addressLocality"] == "Stockholm"
      assert schema["jobLocation"]["address"]["addressCountry"] == "SE"
      assert schema["employmentType"] == "FULL_TIME"
    end

    test "creates JobPosting with all optional fields" do
      schema = SEO.job_posting(
        title: "Senior Developer",
        description: "<p>We need a developer</p>",
        company_name: "Acme Corp",
        location: "Stockholm",
        url: "/jobs/senior-developer",
        company_logo: "https://example.com/logo.png",
        company_url: "https://example.com",
        posted_date: ~D[2024-01-01],
        expiry_date: ~D[2024-12-31],
        employment_type: :part_time,
        remote_allowed: true,
        salary_min: 50000,
        salary_max: 80000,
        salary_currency: "SEK",
        application_url: "https://example.com/apply"
      )

      assert schema["hiringOrganization"]["logo"] == "https://example.com/logo.png"
      assert schema["hiringOrganization"]["sameAs"] == "https://example.com"
      assert schema["datePosted"] == "2024-01-01"
      assert schema["validThrough"] == "2024-12-31"
      assert schema["employmentType"] == "PART_TIME"
      assert schema["jobLocationType"] == "TELECOMMUTE"
      assert schema["baseSalary"]["@type"] == "MonetaryAmount"
      assert schema["baseSalary"]["currency"] == "SEK"
      assert schema["baseSalary"]["value"]["minValue"] == 50000
      assert schema["baseSalary"]["value"]["maxValue"] == 80000
      assert schema["applicationContact"]["url"] == "https://example.com/apply"
    end

    test "strips HTML from description" do
      schema = SEO.job_posting(
        title: "Developer",
        description: "<p>We need <strong>a developer</strong></p>",
        company_name: "Acme",
        location: "Stockholm",
        url: "/jobs/dev"
      )

      assert schema["description"] == "We need a developer"
    end

    test "handles different employment types" do
      types = [
        {:full_time, "FULL_TIME"},
        {:part_time, "PART_TIME"},
        {:contract, "CONTRACT"},
        {:temporary, "TEMPORARY"},
        {:intern, "INTERN"},
        {:volunteer, "VOLUNTEER"},
        {:per_diem, "PER_DIEM"},
        {:other, "OTHER"}
      ]

      for {atom_type, expected} <- types do
        schema = SEO.job_posting(
          title: "Job",
          description: "Description",
          company_name: "Company",
          location: "Location",
          url: "/job",
          employment_type: atom_type
        )

        assert schema["employmentType"] == expected
      end
    end

    test "prefers application_url over application_email" do
      schema = SEO.job_posting(
        title: "Job",
        description: "Description",
        company_name: "Company",
        location: "Location",
        url: "/job",
        application_url: "https://apply.com",
        application_email: "jobs@example.com"
      )

      assert schema["applicationContact"]["url"] == "https://apply.com"
      refute Map.has_key?(schema["applicationContact"], "email")
    end

    test "uses application_email when no URL provided" do
      schema = SEO.job_posting(
        title: "Job",
        description: "Description",
        company_name: "Company",
        location: "Location",
        url: "/job",
        application_email: "jobs@example.com"
      )

      assert schema["applicationContact"]["email"] == "jobs@example.com"
    end

    test "raises ArgumentError when required fields are missing" do
      assert_raise ArgumentError, "title is required for job_posting", fn ->
        SEO.job_posting(
          description: "Description",
          company_name: "Company",
          location: "Location",
          url: "/job"
        )
      end

      assert_raise ArgumentError, "description is required for job_posting", fn ->
        SEO.job_posting(
          title: "Job",
          company_name: "Company",
          location: "Location",
          url: "/job"
        )
      end
    end
  end

  describe "job_postings_list/1" do
    test "creates ItemList schema with multiple job postings" do
      job_postings = [
        [
          title: "Developer",
          description: "Dev job",
          company_name: "Acme",
          location: "Stockholm",
          url: "/jobs/dev"
        ],
        [
          title: "Designer",
          description: "Design job",
          company_name: "Acme",
          location: "Gothenburg",
          url: "/jobs/design"
        ]
      ]

      schema = SEO.job_postings_list(job_postings)

      assert schema["@context"] == "https://schema.org"
      assert schema["@type"] == "ItemList"
      assert length(schema["itemListElement"]) == 2

      first_item = Enum.at(schema["itemListElement"], 0)
      assert first_item["@type"] == "ListItem"
      assert first_item["position"] == 1
      assert first_item["item"]["@type"] == "JobPosting"
      assert first_item["item"]["title"] == "Developer"
      assert first_item["item"]["@id"] == "/jobs/dev"

      second_item = Enum.at(schema["itemListElement"], 1)
      assert second_item["position"] == 2
      assert second_item["item"]["title"] == "Designer"
    end

    test "handles empty list" do
      schema = SEO.job_postings_list([])

      assert schema["@type"] == "ItemList"
      assert schema["itemListElement"] == []
    end
  end

  describe "format_date/1" do
    test "formats different date types" do
      # Access the private function through job_posting
      job_posting = SEO.job_posting(
        title: "Job",
        description: "Desc",
        company_name: "Company",
        location: "Location",
        url: "/job",
        posted_date: ~D[2024-01-01],
        expiry_date: ~U[2024-12-31 23:59:59Z]
      )

      assert job_posting["datePosted"] == "2024-01-01"
      assert job_posting["validThrough"] == "2024-12-31T23:59:59Z"
    end
  end
end