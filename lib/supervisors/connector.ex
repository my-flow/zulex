import Logger

defmodule Reader.Connector do
    use Supervisor


    def start_link do
        Supervisor.start_link(__MODULE__, nil, name: :Connector)
    end


    def init(_) do
        Logger.debug "Starting #{inspect __MODULE__}"
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
        :ok = Supervisor.terminate_child(:Connector, Reader.QueueClient)
        :ok = Supervisor.delete_child(:Connector, Reader.QueueClient)
    end
end
