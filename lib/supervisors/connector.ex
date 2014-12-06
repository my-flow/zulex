defmodule Reader.Connector do
    use Supervisor

    import Logger


    def start_link do
        Supervisor.start_link(__MODULE__, nil, name: :Connector)
    end


    def init(_) do
        info "Starting #{inspect __MODULE__}"
        children = [
            worker(Reader.QueueClient, [], restart: :transient)
        ]
        supervise(children, [strategy: :rest_for_one, max_seconds: 20])
    end


    def read_messages do
        {:ok, _} = Supervisor.start_child(
            :Connector,
            worker(Reader.MessageClient, [], restart: :transient)
        )

        Supervisor.terminate_child(:Connector, Reader.QueueClient)
    end


    def mute_messages do
        Reader.MessageClient.remove_display_handler
    end


    def unmute_messages do
        Reader.MessageClient.add_display_handler
    end
end
