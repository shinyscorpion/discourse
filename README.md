# Discourse

[![Hex.pm](https://img.shields.io/hexpm/v/discourse.svg "Hex")](https://hex.pm/packages/discourse)
[![Build Status](https://travis-ci.org/shinyscorpion/discourse.svg?branch=master)](https://travis-ci.org/shinyscorpion/discourse)
[![Coverage Status](https://coveralls.io/repos/github/shinyscorpion/discourse/badge.svg?branch=master)](https://coveralls.io/github/shinyscorpion/discourse?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/l/discourse.svg "License")](LICENSE)

Simple Discourse library including SSO support.

## Installation

The package can be installed
by adding `discourse` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:discourse, "~> 0.0.1"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/discourse](https://hexdocs.pm/discourse).

## Quick Start

Configure `:discourse`:
```elixir
config :discourse,
  url: "http://discuss.example.com",
  secret: "d836444a9e4084d5b224a60c208dce14"
```

### SSO

Handle login request: (based on Phoenix)
```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  alias Discourse.SSO

  def login(conn, %{"sso" => sso, "sig" => sig}) do
    {:ok, nonce} = SSO.validate(sso, sig)

    # User login
    user = get_session(conn, :user)

    redirect(conn, external: SSO.sign_url(user.id, user.email, nonce))
  end
end
```

## Copyright and License

Copyright (c) 2018, SQUARE ENIX LTD.

Discourse code is licensed under the [MIT License](LICENSE).
