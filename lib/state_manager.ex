import Logger

defmodule StateManager do
    use ExActor.GenServer, export: :StateManager


    defmodule State do
        defstruct queue_id: -1, event_id: -1, credentials: nil
    end


    def init(credentials = %ZulipAPICredentials{}) do
        Logger.debug "Starting #{inspect __MODULE__}"
        initial_state %State{:credentials => credentials}
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


    defcall get_credentials, state: %State{credentials: credentials} do
        reply credentials
    end
end
