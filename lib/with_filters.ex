defmodule WithFilters do
  @moduledoc """
  Provides utility functions to reduce boilerplate when introducing filtering
  from map/struct.

  ## Basic usage

  ```elixir
  defmodule Acme.Deals.DealQuery do
    use WithFilters

    def list_deals do
      Deal
      |> with_filters(%{client_budget: 1_000, status: :finished})
      |> Repo.all()
    end

    def with_filter(query, {:status, status}) when is_deal_status(status) do
      where(query, [deal], deal.status == ^status)
    end

    def with_filter(query, {:client_budget, client_budget}) when is_integer(client_budget) do
      where(query, [deal], deal.client_budget == ^client_budget)
    end

    ...
  ```

  If there is no clause for filter than `Logger.warning/1` macro will be invoked.

  ## Ignore specific filters

  You can ignore specific filters to avoid receiving warning from Logger like that:

  ```elixir
  use WithFilters, ignored: [:page, :page_size]
  ```

  ## Optional filters

  You can automatically skip filter if it's value is `nil` with `:optional` option:

  ```elixir
  use WithFilters, optional: [:action]
  ```

  ## Notice

  Be advised that library is intended to be used only with atom keys. That's is on
  purpose. Never trust user input.
  """

  @callback with_filter(Ecto.Query.t(), {atom(), any()}) :: Ecto.Query.t()

  defmacro __using__(opts) do
    ignored = Keyword.get(opts, :ignored)
    optional = Keyword.get(opts, :optional)

    quote do
      @behaviour WithFilters

      require Logger

      def with_filters(query, filters) when is_struct(filters) do
        with_filters(query, Map.from_struct(filters))
      end

      def with_filters(query, filters) when is_map(filters) or is_list(filters) do
        Enum.reduce(filters, query, &with_filter(&2, &1))
      end

      if unquote(ignored) do
        def with_filter(query, {filter, _}) when filter in unquote(ignored), do: query
      end

      if unquote(optional) do
        def with_filter(query, {filter, nil}) when filter in unquote(optional), do: query
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def with_filter(query, {filter, value}) do
        Logger.warning(
          "Unhandled filter #{filter} with value #{inspect(value)} in #{inspect(__MODULE__)}"
        )

        query
      end
    end
  end
end
