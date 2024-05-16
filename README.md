# WithFilters

**Provides utility to easy reduce filters on query**

## Installation

```elixir
def deps do
  [
    {:with_filters, git: "https://github.com/senconscious/with_filters.git", tag: "0.0.1"}
  ]
end
```

## Usage

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
