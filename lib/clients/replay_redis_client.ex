defmodule ReplayRedisClient do
    @behaviour ReplayClient
    use ExActor.Strict, export: :ReplayClient

    import Logger


    defstart start_link(redis_connection_string) do
        info "Starting #{inspect __MODULE__}"
        {:ok, _} = GenEvent.start_link(name: :ReplayManager)
        initial_state redis_connection_string
    end


    defcall replay_messages(options), state: redis_connection_string, export: false do
        opts = Dict.merge [count: 1_000_000, resort: false, filter: []], options

        messages = ArchiveRedisHelper.get(redis_connection_string, StateManager.get_credentials.email)
            |> Stream.map(&MessageProcessor.process_response_body(&1))
            |> Stream.filter(&(Enum.all?(opts[:filter], fn {k, v} -> Dict.get(&1, k) === v end)))
            |> Stream.take(opts[:count])
            |> Enum.reverse

        :ok = GenEvent.add_handler(:ReplayManager, DisplayHandler, Dict.take(opts, [:resort]))
        GenEvent.notify(:ReplayManager, messages)
        reply GenEvent.remove_handler(:ReplayManager, DisplayHandler, Dict.take(opts, [:resort]))
    end

end
