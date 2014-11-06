import Logger

defmodule ReplayClient do
    use ExActor.Strict, export: :ReplayClient


    definit do
        Logger.info "Starting #{inspect __MODULE__}"
        {:ok, _} = GenEvent.start_link(name: :ReplayManager)
        :ok = GenEvent.add_handler(:ReplayManager, DisplayHandler, [resort: false])
        initial_state nil
    end


    defcall replay_messages(options), export: false do
        opts = Dict.merge [count: 1_000_000, order: :grouped], options
        stream = File.stream!(ArchiveHelper.get_link_to_latest_log_file, [:read, :utf8])

        messages = Enum.map(
            Enum.reverse(Stream.take(Enum.reverse(stream), opts[:count])),
            &MessageProcessor.process_response_body(&1)
        )

        reply GenEvent.notify(:ReplayManager, messages)
    end
end
