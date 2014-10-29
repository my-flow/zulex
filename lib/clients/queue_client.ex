import Logger
import Supervisor.Spec

defmodule QueueClient do
    use ExActor.Tolerant


    defmodule State do
        defstruct event_id: -1, async_id: -1, credentials: nil
    end


    def start_link(credentials = %ZulipAPICredentials{}, opts) do
        GenServer.start_link(__MODULE__, %State{:credentials => credentials}, opts)
    end


    defcall register_queue,
    state: state = %State{:credentials => %ZulipAPICredentials{key: key, email: email}} do

        HTTPotion.start
        ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

        try do
            %HTTPotion.AsyncResponse{id: async_id} = QueueProcessor.post(
                "",
                URI.encode_query(%{
                    "event_types" => JSEX.encode!(["message"])
                }),
                [
                    {"Content-Type", "application/x-www-form-urlencoded"}
                ],
                [
                    stream_to: self,
                    ibrowse: ibrowse
                ]
            )
            set_and_reply %{state | :async_id => async_id}, async_id
        rescue
            e in HTTPotion.HTTPError ->
                Logger.error "#{__MODULE__}: #{e.message}"
                reply {:error, e.message}
        end
    end


    defcall update_event_id(event_id), state: state = %State{} do
        set_and_reply %{state | :event_id => event_id}, event_id
    end


    definfo %HTTPotion.AsyncHeaders{id: id, status_code: status_code},
    state: %State{:async_id => async_id, :credentials => credentials},
    export: false, when: id == async_id do

        unless status_code in 200..299 or status_code in [302, 304] do
            Logger.error "Request failed with HTTP status code #{status_code}."
            new_state %State{:credentials => credentials}
        end
        noreply
    end


    definfo %HTTPotion.AsyncChunk{id: id, chunk: json},
    state: %State{:async_id => async_id, :credentials => credentials},
    export: false, when: is_map(json) and id == async_id do

        if (json[:result] == "error"), do:
            Logger.warn json[:msg]

        request_messages(json[:queue_id], json[:last_event_id], credentials)
        noreply
    end


    definfo %HTTPotion.AsyncEnd{id: id},
    state: %State{:async_id => async_id}, export: false, when: id == async_id do
        noreply
    end


    definfo {:DOWN, _, :process, pid, _} do
        Supervisor.restart_child(ZulEx.Supervisor, pid)
        Process.monitor(:messageClient)
        MessageClient.request_new_messages(:messageClient)
        noreply
    end


    definfo {_, {:error, {_, {:error, reason}}}} do
        Logger.error "#{__MODULE__}: #{to_string(reason)}"
        noreply
    end


    definfo {_, {:error, reason}} do
        Logger.error "#{__MODULE__}: #{to_string(reason)}"
        noreply
    end


    definfo msg, export: false do
        Logger.debug("Ignoring #{inspect msg}")
        noreply
    end


    # private functions

    defp request_messages(queue_id, event_id, credentials) do
        unless Process.whereis(:messageClient) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(MessageClient, [MessageLogger, "", credentials, [name: :messageClient]])
            )
            Process.monitor(:messageClient)
        end
        MessageClient.set_parameters(:messageClient, queue_id, event_id)
        MessageClient.request_new_messages(:messageClient)
    end
end
