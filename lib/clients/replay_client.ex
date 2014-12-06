defmodule ReplayClient do
    use ExActor.Strict, export: :ReplayClient

    import Logger


    defstart start_link do
        info "Starting #{inspect __MODULE__}"
        {:ok, _} = GenEvent.start_link(name: :ReplayManager)
        initial_state nil
    end


    defcall replay_messages(options), export: false do
        opts = Dict.merge [count: 1_000_000, resort: false, filter: []], options

        stream = Stream.concat(Enum.map(ArchiveHelper.get_all_log_files!, &(File.stream!(&1, [:read, :utf8]))))
        messages =
            Enum.reverse(
                Stream.take(
                    Enum.reverse(
                        Stream.filter(
                            Stream.map(
                                stream,
                                &MessageProcessor.process_response_body(&1)
                            ),
                            &(Enum.all?(
                                opts[:filter],
                                fn {k, v} -> Dict.get(&1, k) === v end
                            ))
                        )
                    ),
                    opts[:count]
                )
            )

        :ok = GenEvent.add_handler(:ReplayManager, DisplayHandler, Dict.take(opts, [:resort]))
        GenEvent.notify(:ReplayManager, messages)
        reply GenEvent.remove_handler(:ReplayManager, DisplayHandler, Dict.take(opts, [:resort]))
    end

end
