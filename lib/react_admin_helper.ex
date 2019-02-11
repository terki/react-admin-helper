defmodule ReactAdminHelper do
  @moduledoc """
  Documentation for ReactAdminHelper.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      import ReactAdminHelper.ReactAdminHelper
    end
  end

  defmacro react_admin_context(schema, table, repo) do
    quote do
      def unquote(:"count_#{table}")() do
        Repo = unquote(repo)
        {:ok, %{count: Repo.aggregate(unquote(schema), :count, :id)}}
      end

      def unquote(:"list_paginated_#{table}")(args \\ %{}) do
        Repo = unquote(repo)
        args = Map.put_new(args, :page, nil)
        args = Map.put_new(args, :per_page, nil)
        args = Map.put_new(args, :sort_field, "id")
        args = Map.put_new(args, :sort_order, :asc)
        args = Map.put_new(args, :filter, %{ids: []})
        filter = args.filter
        filter = Map.put_new(filter, :ids, [])
        args = Map.put(args, :filter, filter)

        page =
          case args.page do
            nil -> nil
            argspage -> argspage + 1
          end

        sort_field_atom =
          case args.sort_field do
            "id" ->
              :id

            "key" ->
              :key

            "name" ->
              :name
              # TODO make generic / dynamic / iterate over atoms?
          end

        sort_args =
          case args.sort_order do
            :desc -> {:desc, sort_field_atom}
            :asc -> {:asc, sort_field_atom}
          end

        q = unquote(schema)

        q = where(q, [u], u.id in ^args.filter.ids or ^Enum.empty?(args.filter.ids) == true)

        q = order_by(q, ^sort_args)

        Repo.paginate(q, page: page, page_size: args.per_page)
      end
    end
  end

  defmacro react_admin_query_schema(entity, entities, resolver) do
    quote do
      field(unquote(entity), unquote(entity)) do
        arg(:id, non_null(:id))
        # resolve(&Resolvers.Alert.get_alert/3)
        resolve(
          unquote(
            {:&, [],
             [
               {:/, [context: Elixir, import: Kernel],
                [
                  {{:., [], [resolver, :"get_#{entity}"]}, [], []},
                  3
                ]}
             ]}
          )
        )
      end

      field(unquote(:"all_#{entities}"), list_of(unquote(entity))) do
        arg(:page, :integer)
        arg(:per_page, :integer)
        arg(:sort_field, :string)
        arg(:sort_order, type: :sort_order, default_value: :asc)
        arg(:filter, unquote(:"#{entity}_filter"))
        # resolve(&Resolvers.Alert.all_alerts/3)
        resolve(
          unquote(
            {:&, [],
             [
               {:/, [context: Elixir, import: Kernel],
                [
                  {{:., [], [resolver, :"all_#{entities}"]}, [], []},
                  3
                ]}
             ]}
          )
        )
      end

      field(unquote(:"_all_#{entities}_meta"), :list_metadata) do
        arg(:page, :integer)
        arg(:per_page, :integer)
        arg(:sort_field, :string)
        arg(:sort_order, :string)
        arg(:filter, unquote(:"#{entity}_filter"))
        # resolve(&Resolvers.Alert._all_alerts_meta/3)
        resolve(
          unquote(
            {:&, [],
             [
               {:/, [context: Elixir, import: Kernel],
                [
                  {{:., [], [resolver, :"_all_#{entities}_meta"]}, [], []},
                  3
                ]}
             ]}
          )
        )
      end
    end
  end

  defmacro react_admin_query_resolver(entity, entities, context) do
    quote do
      def unquote(:"get_#{entity}")(_parent, %{id: id}, %{
            context: %{current_user: %{is_admin: true}}
          }) do
        # an_entity = MyProjectCore.Accounts.get_alert!(id)
        # an_entity = MyProjectCore.Accounts.get_alert!(unquote(Macro.var(:id,__MODULE__)))
        an_entity =
          unquote({{:., [], [context, :"get_#{entity}!"]}, [], [Macro.var(:id, __MODULE__)]})

        Map.put(
          an_entity,
          :inserted_at,
          DateTime.from_naive!(an_entity.inserted_at, "Etc/UTC")
        )

        {:ok, an_entity}
      end

      def unquote(:"get_#{entity}")(_, _, _) do
        not_authorized()
      end

      def unquote(:"all_#{entities}")(_parent, args = %{}, %{
            context: %{current_user: %{is_admin: true}}
          }) do
        some_entities =
          case args do
            # %{filter: %{q: q}} ->
            #  MyProjectCore.Accounts.get_alerts_by_filter(q)

            # unquote({{:., [],
            # [
            #  context,
            #  :"get_#{entities}_by_filter"
            # ]}, [], [{:q, [], Elixir}]})
            _ ->
              # MyProjectCore.Accounts.list_paginated_alerts(args)
              unquote(
                {{:., [],
                  [
                    context,
                    :"list_paginated_#{entities}"
                  ]}, [], [Macro.var(:args, __MODULE__)]}
              )
              |> Enum.map(fn an_entity ->
                an_entity
                # Map.put(
                # an_entity,
                # :inserted_at,
                # DateTime.from_naive!(an_entity.inserted_at, "Etc/UTC")
                # )
              end)
          end

        {:ok, some_entities}
      end

      def unquote(:"all_#{entities}")(_, _, _) do
        not_authorized()
      end

      def unquote(:"_all_#{entities}_meta")(_parent, _args, %{
            context: %{current_user: %{is_admin: true}}
          }) do
        # MyProjectCore.Accounts.count_alerts()
        unquote(
          {{:., [],
            [
              context,
              :"count_#{entities}"
            ]}, [], []}
        )
      end

      def unquote(:"_all_#{entities}_meta")(_, _, _) do
        not_authorized()
      end

      defp not_authorized() do
        {:error, "Not authorized"}
      end
    end
  end

  defmacro react_admin_mutation_resolver(entity, _entities, context) do
    quote do
      def unquote(:"create_#{entity}")(_parent, args, %{
            context: %{current_user: %{is_admin: true}}
          }) do
        with(
          {:ok, changeset} <-
            unquote(
              {{:., [],
                [
                  context,
                  :"create_#{entity}"
                ]}, [], [Macro.var(:args, __MODULE__)]}
            )
          # _ <- Mqtt.notify_blacklist_update()
        ) do
          {:ok, changeset}
        else
          {:error, changeset} ->
            IO.inspect(changeset, label: "Error when creating")
            {:error, "Error when creating"}
        end
      end

      def unquote(:"create_#{entity}")(_, _, _) do
        not_authorized()
      end

      def unquote(:"update_#{entity}")(_parent, args = %{id: id}, %{
            context: %{current_user: %{is_admin: true}}
          }) do
        an_entity =
          unquote(
            {{:., [],
              [
                context,
                :"get_#{entity}!"
              ]}, [], [Macro.var(:id, __MODULE__)]}
          )

        result =
          unquote(
            {{:., [],
              [
                context,
                :"update_#{entity}"
              ]}, [], [Macro.var(:an_entity, __MODULE__), Macro.var(:args, __MODULE__)]}
          )

        case result do
          {:ok, _changeset} ->
            # Mqtt.notify_blacklist_update()
            result

          {:error, changeset} ->
            IO.inspect(changeset, label: "Error when updating")
            {:error, "Internal server error"}
        end
      end

      def unquote(:"update_#{entity}")(_, _, _) do
        not_authorized()
      end

      def unquote(:"delete_#{entity}")(_parent, %{id: id}, %{
            context: %{current_user: %{is_admin: true}}
          }) do
        # Mqtt.notify_blacklist_update()

        an_entity =
          unquote(
            {{:., [],
              [
                context,
                :"get_#{entity}!"
              ]}, [], [Macro.var(:id, __MODULE__)]}
          )

        unquote(
          {{:., [],
            [
              context,
              :"delete_#{entity}"
            ]}, [], [Macro.var(:an_entity, __MODULE__)]}
        )
      end

      def unquote(:"delete_#{entity}")(_, _, _) do
        not_authorized()
      end
    end
  end
end
