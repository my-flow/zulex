import Logger

defmodule MessageClient do
    use ExActor.Tolerant

    @default_queue_id -1
    @default_event_id -1
    @default_async_id -1


    def start_link(handler, args, credentials = %ZulipAPICredentials{}, opts) do
        GenEvent.start_link(name: :eventManager)
        GenEvent.add_handler(:eventManager, handler, args)
        GenServer.start_link(__MODULE__, {@default_queue_id, @default_event_id, @default_async_id, credentials}, opts)
    end


    defcall set_parameters(queue_id, last_event_id), state: {_, _, async_id, credentials} do
        set_and_reply {queue_id, last_event_id, async_id, credentials}, :ok
    end


    defcast request_new_messages, 
    state: {queue_id, last_event_id, _, credentials = %ZulipAPICredentials{key: key, email: email}} do

        HTTPotion.start
        ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

        try do
            %HTTPotion.AsyncResponse{id: id} = MessageProcessor.get(
                URI.encode_query(%{
                    "queue_id"      => queue_id,
                    "last_event_id" => last_event_id
                }),
                [], # empty headers
                [
                    stream_to: self,
                    ibrowse:   ibrowse,
                    timeout:   600_000
                ]
            )
            new_state {queue_id, last_event_id, id, credentials} # set async_id <= id
        rescue
            e in HTTPotion.HTTPError ->
                Logger.error "#{__MODULE__}: #{e.message}"
            noreply
        end
    end


    definfo %HTTPotion.AsyncHeaders{id: id, status_code: status_code}, 
    state: {_, _, async_id, credentials}, export: false, when: id == async_id do

        unless status_code in 200..299 or status_code in [302, 304] do
            Logger.error "Request failed with HTTP status code #{status_code}."
            new_state {@default_queue_id, @default_event_id, @default_async_id, credentials}
        end
        noreply
    end


    definfo %HTTPotion.AsyncChunk{id: id, chunk: json}, 
    state: {queue_id, last_event_id, async_id, credentials}, 
    export: false, when: is_map(json) and id == async_id do

        if (json[:result] == "error"), do:
            Logger.warn json[:msg]

        if (Dict.has_key? json, :events) do
            events = Dict.get(json, :events)

            messages = Enum.filter_map(events, fn e -> e[:message] != nil end, fn e -> e[:message] end)
            unless Enum.empty?(messages), do:
                GenEvent.notify(:eventManager, messages)

            max_event_id = List.foldl(
                events,
                last_event_id,
                fn e, acc -> max(e[:id], acc) end
            )
            new_state {queue_id, max_event_id, async_id, credentials}
        else
            new_state {@default_queue_id, @default_event_id, @default_async_id, credentials}
        end
    end


    definfo %HTTPotion.AsyncChunk{id: id, chunk: {:error, reason}}, 
    state: {_, _, async_id, _}, export: false, when: id == async_id do

        Logger.error "#{__MODULE__}: #{inspect reason}"
        __MODULE__.request_new_messages(self)
        noreply
    end


    definfo %HTTPotion.AsyncEnd{id: id}, state: {_, last_event_id, async_id, _}, export: false, when: id == async_id do
        QueueClient.update_last_event_id(:queueClient, last_event_id)
        __MODULE__.request_new_messages(self)
        noreply
    end


    definfo msg, export: false do
        Logger.debug("Ignoring #{inspect msg}")
        noreply
    end
end
