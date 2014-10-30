import Logger
import Supervisor.Spec

defmodule StateHandler do
    use ExActor.GenServer, export: :stateHandler


    defmodule State do
        defstruct queue_id: -1, event_id: -1, credentials: nil
    end


    def start_link(opts) do
        GenServer.start_link(__MODULE__, %State{}, opts)
    end


    def authenticate(name, handle_undefined \\ :ask) do
        unless Process.whereis(:sessionHandler) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(SessionHandler, [[name: :sessionHandler, restart: :transient]])
            )
        end
        credentials = SessionHandler.authenticate(handle_undefined)
        __MODULE__.set_credentials(credentials)
    end


    defcall set_queue_id_and_event_id(queue_id, event_id), state: state = %State{} do
        set_and_reply %{state | :queue_id => queue_id, :event_id => event_id}, state
    end


    defcall set_event_id(event_id), state: state = %State{} do
        set_and_reply %{state | :event_id => event_id}, state
    end


    defcall get_state, state: state = %State{} do
        reply state
    end


    defcall set_credentials(credentials), state: state = %State{} do
        set_and_reply %{state | :credentials => credentials}, credentials
    end


    defcall get_credentials, state: %State{credentials: credentials} do
        reply credentials
    end


    defcallp set_credentials(credentials = %ZulipAPICredentials{}), state: state = %State{} do
        set_and_reply %{state | :credentials => credentials}, credentials
    end
end
