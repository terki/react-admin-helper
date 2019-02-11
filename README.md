# ReactAdminHelper

Provides convenience macros for bootstrapping React Admin compatible GraphQL APIs via ra-data-graphql-simple.
This helper assumes a graphql context containing %{current_user: %{is_admin: true} is set for valid admin users.

## Usage

In your context created/modified by `mix phx.gen.context Post posts title` (in this example "Posts"), add 

```elixir
use ReactAdminHelper
react_admin_context(Post, "posts", Repo)
```

Create your resolver like so

```elixir
defmodule MyProjectCoreWeb.Resolvers.Post do
  use ReactAdminHelper.ReactAdminHelper
  react_admin_query_resolver(:post, :posts, MyProjectCore.Posts)
  react_admin_mutation_resolver(:post, :posts, MyProjectCore.Posts)
end
```

In your graphql schema, define your :post and add

```elixir
  use ReactAdminHelper
  query(name: "Query") do
    react_admin_query_schema(:post, :posts, Resolvers.Post)
  end
  mutation(name: "Mutation") do
    field(:create_post, :post) do
      arg(:title, :string)
      resolve(&Resolvers.Post.create_post/3)
    end    
    field(:update_post, :post) do
      arg(:id, :id)
      arg(:title, :string)
      resolve(&Resolvers.Post.update_post/3)
    end
    field(:delete_post, :post) do
      arg(:id, non_null(:id))      
      resolve(&Resolvers.Post.delete_post/3)
    end
  end
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `react_admin_helper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:react_admin_helper, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/react_admin_helper](https://hexdocs.pm/react_admin_helper).

