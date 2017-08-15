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

Add `elasticfusion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:elasticfusion, github: "fanuniverse/elasticfusion", tag: "1.1.0"}]
end
```

Specify your Elasticsearch endpoint in `config.exs`:

```elixir
config :elasticfusion, endpoint: "http://localhost:9200"
```
