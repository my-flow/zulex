import Logger

defmodule MessageClient do
    use ExActor.Tolerant


    defmodule State do
        defstruct queue_id: -1, event_id: -1, async_id: -1, credentials: nil
    end


    def start_link(handler, args, credentials = %ZulipAPICredentials{}, opts) do
        GenEvent.start_link(name: :eventManager)
        GenEvent.add_handler(:eventManager, handler, args)
        GenServer.start_link(__MODULE__, %State{:credentials => credentials}, opts)
    end


    defcall set_parameters(queue_id, event_id), state: state do
        set_and_reply %{state | :queue_id => queue_id, :event_id => event_id}, :ok
    end


    defcall request_new_messages, state: state = %State{} do
        try do
            %HTTPotion.AsyncResponse{id: async_id} = _request_new_messages(state)
            set_and_reply %{state | :async_id => async_id}, async_id
        rescue
            e in HTTPotion.HTTPError ->
                Logger.error "#{__MODULE__}: #{e.message}"
                reply {:error, e.message}
        end
    end


    definfo %HTTPotion.AsyncHeaders{id: id, status_code: status_code}, 
    state: %State{:async_id => async_id, :credentials => credentials}, export: false, when: id == async_id do

        unless status_code in 200..299 or status_code in [302, 304] do
            Logger.error "Request failed with HTTP status code #{status_code}."
            new_state %State{:credentials => credentials}
        end
        noreply
    end


    definfo %HTTPotion.AsyncChunk{id: id, chunk: json}, 
    state: state = %State{:event_id => event_id, :async_id => async_id, :credentials => credentials}, 
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
                event_id,
                fn e, acc -> max(e[:id], acc) end
            )
            new_state %{state | :event_id => max_event_id}
        else
            new_state %State{:credentials => credentials}
        end
    end


    definfo %HTTPotion.AsyncChunk{id: id, chunk: {:error, reason}}, 
    state: %State{:async_id => async_id}, export: false, when: id == async_id do

        Logger.error "#{__MODULE__}: #{inspect reason}"
        __MODULE__.request_new_messages(self)
        noreply
    end


    definfo %HTTPotion.AsyncEnd{id: id},
    state: state = %State{:event_id => event_id, :async_id => async_id}, export: false, when: id == async_id do
        QueueClient.update_event_id(:queueClient, event_id)
        try do
            %HTTPotion.AsyncResponse{id: async_id} = _request_new_messages(state)
            new_state %{state | :async_id => async_id}
        rescue
            e in HTTPotion.HTTPError ->
                Logger.error "#{__MODULE__}: #{e.message}"
                noreply
        end
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

    defp _request_new_messages(
        %State{:queue_id => queue_id, :event_id => event_id, :credentials => %ZulipAPICredentials{key: key, email: email}}) do

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
