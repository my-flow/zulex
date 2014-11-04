ZulEx
=====

A reactive [Zulip](https://zulip.com) reader in Elixir/Erlang with real-time updates.


## Using the Client

### Installation

1. Clone the repository with `git clone git@github.com:my-flow/zulex.git`.
2. Install the required dependencies with `mix deps.get`.
3. Start Elixir's interactive shell with `ZULIP_USERNAME=john.doe@example.com ZULIP_API_KEY=abc123 iex -S mix`. You will see incoming messages in real-time.


### Pause incoming messages
You can mute messages temporarily with

```
iex(1)> ZulEx.pause_messages
```

and switch them on again with

```
iex(2)> ZulEx.read_messages
```


## Proxy Settings
Find sample configurations in `config/config.exs` that show how to set up proxy authentication and SOCKS5.


## Copyright & License

Copyright (c) 2014 [Florian J. Breunig](http://www.my-flow.com)

Licensed under MIT, see LICENSE file.
