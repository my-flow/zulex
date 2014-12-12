defmodule ReplayFileClient do
    @behaviour ReplayClient
    use ExActor.Strict, export: :ReplayClient

    import Logger


    defstart start_link do
        info "Starting #{inspect __MODULE__}"
        {:ok, _} = GenEvent.start_link(name: :ReplayManager)
        initial_state nil
    end


    defcall replay_messages(options), export: false do
        opts = Dict.merge [count: 1_000_000, resort: false, filter: []], options

        messages = ArchiveFileHelper.get_all_log_files!(StateManager.get_credentials.email)
            |> Enum.map(&(File.stream!(&1, [:read, :utf8])))
            |> Stream.concat
            |> Stream.map(&MessageProcessor.process_response_body(&1))
            |> Stream.filter(&(Enum.all?(opts[:filter], fn {k, v} -> Dict.get(&1, k) === v end)))
            |> Enum.reverse
            |> Stream.take(opts[:count])
            |> Enum.reverse

        :ok = GenEvent.add_handler(:ReplayManager, DisplayHandler, Dict.take(opts, [:resort]))
        GenEvent.notify(:ReplayManager, messages)
        reply GenEvent.remove_handler(:ReplayManager, DisplayHandler, Dict.take(opts, [:resort]))
    end

end
