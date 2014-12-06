defmodule Reader.QueueClient do
    use ExActor.Strict, export: :QueueClient

    import Logger


    defstart start_link do
        info "Starting #{inspect __MODULE__}"
        register_queue
        initial_state nil
    end


    defcast register_queue, export: false do
        %ZulipAPICredentials{key: key, email: email} = StateManager.get_credentials

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
    end


    defhandleinfo %HTTPotion.AsyncHeaders{id: id, status_code: status_code},
    state: async_id, export: false, when: id == async_id do

        unless status_code in 200..299 or status_code in [302, 304] do
            msg = "#{__MODULE__}: Request failed with HTTP status code #{status_code}."
            error(msg)
            raise RuntimeError, message: msg
        end
        noreply
    end


    defhandleinfo %HTTPotion.AsyncChunk{id: id, chunk: json},
    state: async_id, export: false, when: is_map(json) and id == async_id do

        if (json[:result] == "error"), do:
            error json[:msg]

        StateManager.set_queue_id_and_event_id(json[:queue_id], json[:last_event_id])
        :ok = Reader.Connector.read_messages

        noreply
    end


    defhandleinfo %HTTPotion.AsyncEnd{id: id},
    state: async_id, export: false, when: id == async_id do
        noreply
    end
end
