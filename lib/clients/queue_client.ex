import Logger
import Supervisor.Spec

defmodule QueueClient do
    use ExActor.Tolerant, export: :queueClient


    def start_link(opts) do
        Logger.debug "Starting queue client"
        GenServer.start_link(__MODULE__, nil, opts)
    end


    definit do
        register_queue
        initial_state nil
    end


    defcast register_queue, export: false do

        %ZulipAPICredentials{key: key, email: email} = StateHandler.get_credentials

        try do
            HTTPotion.start
            ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

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
            new_state async_id
        rescue
            e in HTTPotion.HTTPError ->
                Logger.error "#{__MODULE__}: #{e.message}"
                new_state -1
        end
    end


    definfo %HTTPotion.AsyncHeaders{id: id, status_code: status_code},
    state: async_id, export: false, when: id == async_id do

        unless status_code in 200..299 or status_code in [302, 304] do
            Logger.error "Request failed with HTTP status code #{status_code}."
            new_state -1
        end
        noreply
    end


    definfo %HTTPotion.AsyncChunk{id: id, chunk: json},
    state: async_id, export: false, when: is_map(json) and id == async_id do

        if (json[:result] == "error"), do:
            Logger.warn json[:msg]

        request_messages(json[:queue_id], json[:last_event_id])
        noreply
    end


    definfo %HTTPotion.AsyncEnd{id: id},
    state: async_id, export: false, when: id == async_id do
        noreply
    end


    definfo msg, export: false do
        Logger.debug("Ignoring #{inspect msg}")
        noreply
    end


    # private functions

    defp request_messages(queue_id, event_id) do
        StateHandler.set_queue_id_and_event_id(queue_id, event_id)

        if Process.whereis(:messageClient) do
            Supervisor.terminate_child(ZulEx.Supervisor, MessageClient)
            Supervisor.delete_child(ZulEx.Supervisor, MessageClient)
        end

        Supervisor.start_child(
            ZulEx.Supervisor,
            worker(MessageClient, [MessageLogger, "", [name: :messageClient, restart: :transient]])
        )
        Process.monitor(:messageClient)
    end
end
