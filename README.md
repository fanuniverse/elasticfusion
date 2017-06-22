# Elasticfusion

[![Build Status](https://travis-ci.org/fanuniverse/elasticfusion.svg?branch=master)](https://travis-ci.org/fanuniverse/elasticfusion)

A collection of Elixir-flavored Elasticsearch extensions based on the
[elasticfusion](https://github.com/little-bobby-tables/elasticfusion) Ruby Gem.

## Prerequisites

* Docker
* [Docker Compose](https://docs.docker.com/compose/install/)

## Getting up and running

```bash
docker-compose up

mix deps.get

mix test
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elasticfusion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:elasticfusion, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elasticfusion](https://hexdocs.pm/elasticfusion).
