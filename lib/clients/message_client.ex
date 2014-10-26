import Logger

defmodule MessageClient do
    use ExActor.GenServer


    def start_link(queue_id, last_event_id, credentials = %ZulipAPICredentials{}, opts) when is_integer(last_event_id) do
        GenEvent.start_link(name: :eventManager)
        GenServer.start_link(__MODULE__, {queue_id, last_event_id, credentials}, opts)
    end


    defcall request_new_messages(handler, args, last_event_id), state: {queue_id, _, credentials} do
        GenEvent.add_handler(:eventManager, handler, args)
        __MODULE__.request_new_messages(:messageClient)
        set_and_reply {queue_id, last_event_id, credentials}, :ok
    end


    defcast request_new_messages, state: {queue_id, last_event_id, %ZulipAPICredentials{key: key, email: email}} do
        HTTPotion.start
        ibrowse = [
            proxy_host: String.to_char_list("localhost"),
            proxy_port: 8080,
            basic_auth: {
                String.to_char_list(email),
                String.to_char_list(key)
            }
        ]

        MessageProcessor.get(
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
        noreply
    end


    definfo %HTTPotion.AsyncHeaders{status_code: status_code}, export: false do
        unless status_code in 200..299 or status_code in [302, 304] do
            Logger.error "Request failed with HTTP status code #{status_code}."
            new_state {nil, nil, nil}
        end
        noreply
    end


    definfo %HTTPotion.AsyncChunk{chunk: json}, state: {queue_id, last_event_id, credentials}, export: false do
        if (json[:result] == "error"), do:
            Logger.warn "Received the following message from Zulip server: \"#{json[:msg]}\""

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
            new_state {queue_id, max_event_id, credentials}
        else
            new_state {nil, nil, nil}
        end
    end


    definfo %HTTPotion.AsyncEnd{}, state: {_, last_event_id, _}, export: false do
        if (is_integer(last_event_id)) do
            QueueClient.update_last_event_id(:queueClient, last_event_id)
            __MODULE__.request_new_messages(self)
        end
        noreply
    end
end
