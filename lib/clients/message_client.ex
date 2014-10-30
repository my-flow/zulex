import Logger

defmodule MessageClient do
    use ExActor.Tolerant, export: :messageClient


    def start_link(handler, args, opts) do
        GenEvent.start_link(name: :eventManager)
        GenEvent.add_handler(:eventManager, handler, args)
        GenServer.start_link(__MODULE__, nil, opts)
    end


    definit do
        request_new_messages
        initial_state nil
    end


    defcast request_new_messages, export: false do
        try do
            %HTTPotion.AsyncResponse{id: async_id} = _request_new_messages
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

        if (Dict.has_key? json, :events) do
            events = Dict.get(json, :events)

            messages = Enum.filter_map(events, fn e -> e[:message] != nil end, fn e -> e[:message] end)
            unless Enum.empty?(messages), do:
                GenEvent.notify(:eventManager, messages)

            max_event_id = List.foldl(
                events,
                -1,
                fn e, acc -> max(e[:id], acc) end
            )
            StateHandler.set_event_id(max_event_id)
            noreply
        else
            new_state -1
        end
    end


    definfo %HTTPotion.AsyncChunk{id: id, chunk: {:error, reason}}, 
    state: async_id, export: false, when: id == async_id do

        Logger.error "#{__MODULE__}: #{inspect reason}"
        __MODULE__.request_new_messages
        noreply
    end


    definfo %HTTPotion.AsyncEnd{id: id},
    state: async_id, export: false, when: id == async_id do
        try do
            %HTTPotion.AsyncResponse{id: async_id} = _request_new_messages
            new_state async_id
        rescue
            e in HTTPotion.HTTPError ->
                Logger.error "#{__MODULE__}: #{e.message}"
                noreply
        end
    end


    definfo msg, export: false do
        Logger.debug("Ignoring #{inspect msg}")
        noreply
    end


    # private functions

    defp _request_new_messages do

        %StateHandler.State{
            queue_id: queue_id,
            event_id: event_id,
            credentials: %ZulipAPICredentials{key: key, email: email}
        } = StateHandler.get_state


        HTTPotion.start
        ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

        MessageProcessor.get(
            URI.encode_query(%{
                "queue_id"      => queue_id,
                "last_event_id" => event_id
            }),
            [], # empty headers
            [
                stream_to: self,
                ibrowse:   ibrowse,
                timeout:   600_000
            ]
        )
    end
end
