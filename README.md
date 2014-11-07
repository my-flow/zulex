ZulEx
=====

A reactive [Zulip](https://zulip.com) reader in Elixir/Erlang with real-time updates.


## Using the Client

### Installation

1. Clone the repository with `git clone git@github.com:my-flow/zulex.git`.
2. Install the required dependencies with `mix deps.get`.
3. Start Elixir's interactive shell with `ZULIP_USERNAME=john.doe@example.com ZULIP_API_KEY=abc123 iex -S mix`. You will see incoming messages in real-time.


### Mute incoming messages
You can mute all messages temporarily with

```
iex(1)> ZulEx.mute_messages
```

and switch them back on again with

```
iex(2)> ZulEx.unmute_messages
```


### Replay incoming messages

You can replay chat messages even if you muted them before:

```
iex(3)> ZulEx.replay_messages
```

Limit the number of replayed messages:

```
iex(4)> ZulEx.replay_messages count: 10
```

Reread your messages with a filter:

```
iex(5)> ZulEx.replay_messages filter: [display_recipient: "food", subject: "lunch"]
```

Order your messages by stream and by subject (as opposed to by time):

```
iex(6)> ZulEx.replay_messages resort: true
```

Combine all the options above:

```
iex(7)> ZulEx.replay_messages filter: [display_recipient: "food"], count: 20, resort: true
```


## Proxy Settings
Find sample configurations in `config/config.exs` that show how to set up proxy authentication and SOCKS5.


## Copyright & License

Copyright (c) 2014 [Florian J. Breunig](http://www.my-flow.com)

Licensed under MIT, see LICENSE file.
