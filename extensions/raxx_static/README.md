# Raxx.Static

**[Raxx](https://github.com/crowdhailer/raxx) middleware for serving static content.**

[![Hex pm](http://img.shields.io/hexpm/v/raxx_static.svg?style=flat)](https://hex.pm/packages/raxx_static)
[![Build Status](https://secure.travis-ci.org/CrowdHailer/raxx_static.svg?branch=master
"Build Status")](https://travis-ci.org/CrowdHailer/raxx_static)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

- [Install from hex.pm](https://hex.pm/packages/raxx_static)
- [Documentation available on hexdoc](https://hexdocs.pm/raxx_static)
- [Raxx discussion on slack](https://elixir-lang.slack.com/messages/C56H3TBH8/)

## Getting Started

Add routes for static assets to any server module.

```elixir
defmodule MyApp.WWW do
  use Raxx.Server
  use Raxx.Static, "./public"

  @impl Raxx.Server
  def handle_head(request, state) do
  # ...
end
```
