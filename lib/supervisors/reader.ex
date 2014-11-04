import Logger

defmodule Reader do
    use Supervisor


    def start_link(credentials = %ZulipAPICredentials{}) do
        Supervisor.start_link(__MODULE__, credentials, name: :Reader)
    end


    def init(credentials = %ZulipAPICredentials{}) do
        Logger.debug "Starting #{inspect __MODULE__}"
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
            Supervisor.restart_child(
                :Reader,
                Reader.Connector
            )
        end
    end
end
