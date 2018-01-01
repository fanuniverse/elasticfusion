# Elasticfusion

[![Build Status](https://travis-ci.org/fanuniverse/elasticfusion.svg?branch=master)](https://travis-ci.org/fanuniverse/elasticfusion)

A collection of Elixir-flavored Elasticsearch extensions based on the
[elasticfusion](https://github.com/little-bobby-tables/elasticfusion) Ruby Gem.

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

## Development

### Prerequisites

* [Docker CE](https://docker.com/community-edition#/download)
* [Docker Compose](https://docs.docker.com/compose/install/)

* [asdf](https://github.com/asdf-vm/asdf)
* [asdf-erlang](https://github.com/asdf-vm/asdf-erlang)
* [asdf-elixir](https://github.com/asdf-vm/asdf-elixir)

### Getting up and running

```bash
asdf install

docker-compose up

mix deps.get

mix test
```
