defmodule AshJsonApi.ContentNegotiationTest do
  use ExUnit.Case
  import AshJsonApi.Test
  @module_tag :json_api_spec_1_0

  defmodule Author do
    use Ash.Resource, name: "authors", type: "author"
    use AshJsonApi.JsonApiResource
    use Ash.DataLayer.Ets, private?: true

    json_api do
      routes do
        get(:default)
        index(:default)
      end

      fields [:name]
    end

    actions do
      defaults([:read, :create],
        rules: [allow(:static, result: true)]
      )
    end

    attributes do
      attribute(:name, :string)
    end
  end

  defmodule Post do
    use Ash.Resource, name: "posts", type: "post"
    use AshJsonApi.JsonApiResource
    use Ash.DataLayer.Ets, private?: true

    json_api do
      routes do
        get(:default)
        index(:default)
      end

      fields [:name]
    end

    actions do
      defaults([:read, :create],
        rules: [allow(:static, result: true)]
      )
    end

    attributes do
      attribute(:name, :string)
    end

    relationships do
      belongs_to(:author, Author)
    end
  end

  defmodule Api do
    use Ash.Api
    use AshJsonApi.Api

    api do
      resources([Post, Author])
    end
  end

  @tag :spec_must
  describe "Clients MUST send all JSON:API data in request documents with the header Content-Type: application/vnd.api+json without any media type parameters." do
    # N/A
  end

  @tag :spec_must
  describe "Clients that include the JSON:API media type in their Accept header MUST specify the media type there at least once without any media type parameters." do
    # N/A
  end

  @tag :spec_must
  describe "Clients MUST ignore any parameters for the application/vnd.api+json media type received in the Content-Type header of response documents." do
    # N/A
  end

  @tag :spec_must
  describe "Servers MUST send all JSON:API data in response documents with the header Content-Type: application/vnd.api+json without any media type parameters." do
    # TODO: This test should run as part of ALL responses - not just this one off example below, similar to JSON Schema validations
    test "individual resource" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "Hamlet"}})

      # TODO: Content-Type is in capital case on the JSON:API spec, but elixir recommends we use lower case...
      get(Api, "/posts/#{post.id}", resp_headers_include: {"Content-Type", "application/vnd.api+json"})
    end

  end

  @tag :spec_must
  describe "Servers MUST respond with a 415 Unsupported Media Type status code if a request specifies the header Content-Type: application/vnd.api+json with any media type parameters." do
    test "request Content-Type header is not present" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", exclude_req_content_type_header: true, status: 200)
    end

    test "request Content-Type header present but nil" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: nil, status: 200)
    end

    test "request Content-Type header present but blank" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "", status: 200)
    end

    test "request Content-Type header is JSON:API" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "application/vnd.api+json", status: 200)
    end

    test "request Content-Type header is JSON:API modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "application/vnd.api+json; charset=test", status: 415)
    end

    test "request Content-Type header includes JSON:API and JSON:API modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "application/vnd.api+json, application/vnd.api+json; charset=test", status: 415)
    end

    test "request Content-Type header includes two instances of JSON:API modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "application/vnd.api+json; charset=test, application/vnd.api+json; charset=test", status: 415)
    end

    test "request Content-Type header is a random value" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "foo", status: 200)
    end

    test "request Content-Type header is a */*" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "*/*", status: 200)
    end

    test "request Content-Type header is a */* modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "*/*;q=0.8", status: 200)
    end

    test "request Content-Type header is a valid media type other than JSON:API" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_content_type_header: "text/html", status: 200)
    end
  end

  @tag :spec_must
  describe "Servers MUST respond with a 406 Not Acceptable status code if a request’s Accept header contains the JSON:API media type and all instances of that media type are modified with media type parameters." do
    test "request Accept header is not present" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", exclude_req_accept_header: true, status: 200)
    end

    test "request Accept header present but blank" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "", status: 200)
    end

    test "request Accept header present but nil" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: nil, status: 200)
    end

    test "request Accept header is JSON:API" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "application/vnd.api+json", status: 200)
    end

    test "request Accept header is JSON:API modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "application/vnd.api+json; charset=test", status: 406)
    end

    test "request Accept header includes JSON:API and JSON:API modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "application/vnd.api+json, application/vnd.api+json; charset=test", status: 200)
    end

    test "request Accept header includes two instances of JSON:API modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "application/vnd.api+json; charset=test, application/vnd.api+json; charset=test", status: 406)
    end

    test "request Accept header is a random value" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "foo", status: 200)
    end

    test "request Accept header is a */*" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "*/*", status: 200)
    end

    test "request Accept header is a */* modified with a param" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "*/*;q=0.8", status: 200)
    end

    test "request Accept header is a valid media type other than JSON:API" do
      # Create a post
      {:ok, post} = Api.create(Post, %{attributes: %{name: "foo"}})

      get(Api, "/posts/#{post.id}", req_accept_header: "text/html", status: 200)
    end
  end
end
