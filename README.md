# ReactAdminHelper

Provides convenience macros for bootstrapping React Admin compatible GraphQL APIs via ra-data-graphql-simple.

This helper assumes by default a graphql context containing %{current_user: %{is_admin: true} is set for valid admin users, but this can be overridden by providing another matching expression as the optional fourth argument to the resolver macros. To disable security completely you can provide %{} as this argument, matching every map as context.

## Usage

In your Repo, to add pagination, add Scrivener

```elixir
  use Scrivener
```

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
```

## Installation

Add `react_admin_helper` and scrivener and scrivener_ecto to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [    
    {:react_admin_helper, git: "git@github.com:terki/react-admin-helper.git"},
    {:scrivener, "~> 2.5"},
    {:scrivener_ecto, "~> 2.0.0"},
  ]
end
```

## Advanced usage

### Customize access control

The default assumes the context argument to the resolver is a map that contains a context key with a value that matches %{current_user: %{is_admin: true}}. To customize, add the match expression as the fourth argument like so, here matching for current_user with is_root instead:

```elixir
defmodule MyProjectCoreWeb.Resolvers.Post do
  use ReactAdminHelper.ReactAdminHelper
  react_admin_query_resolver(:post, :posts, MyProjectCore.Posts, ‰{context: %{current_user: %{is_root: true}}})
  react_admin_mutation_resolver(:post, :posts, MyProjectCore.Posts, %{context: %{current_user: %{is_root: true}}})
end
```

To override generated methods with a custom implementation, implement them below the macro call.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/react_admin_helper](https://hexdocs.pm/react_admin_helper).

