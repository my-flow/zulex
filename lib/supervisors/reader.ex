defmodule Reader do
    use Supervisor

    import Logger


    def start_link(credentials = %ZulipAPICredentials{}) do
        Supervisor.start_link(__MODULE__, credentials, name: :Reader)
    end


    def init(credentials = %ZulipAPICredentials{}) do
        info "Starting #{inspect __MODULE__}"
        children = [
            worker(StateManager, [credentials], restart: :transient),
            supervisor(Reader.Connector, [], restart: :transient)
        ]
        supervise(children, strategy: :rest_for_one)
    end


    def restart_connector do
        if Process.whereis(:Connector) do
            {:ok, Process.whereis(:Connector)}
        else
            Supervisor.restart_child(:Reader, Reader.Connector)
        end
    end


    def mute_messages do
        Reader.Connector.mute_messages
    end


    def unmute_messages do
        Reader.Connector.unmute_messages
    end
end
