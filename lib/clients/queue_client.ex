import Logger

defmodule QueueClient do
    use ExActor.GenServer


    def start_link(credentials = %ZulipAPICredentials{}, opts) do
        GenServer.start_link(__MODULE__, credentials, opts)
    end


    defcall register_queue, state: %ZulipAPICredentials{key: key, email: email} do
        HTTPotion.start
        ibrowse = [
            proxy_host: String.to_char_list("localhost"),
            proxy_port: 8080,
            basic_auth: {
                String.to_char_list(email),
                String.to_char_list(key)
            }
        ]

        queue_id = last_event_id = nil

        response = QueueProcessor.post(
            "",
            URI.encode_query(%{"event_types" => :jsx.encode(["message"])}),
            [{"Content-Type", "application/x-www-form-urlencoded"}],
            [ibrowse: ibrowse]
        )

        %HTTPotion.Response{body: json, status_code: status_code} = response
        cond do
            !HTTPotion.Response.success?(response) ->
                Logger.error "Request failed with HTTP status code #{status_code}."
            json[:result] == "error" ->
                Logger.warn "Received the following message from Zulip server: \"#{json[:msg]}\""
            true ->
                queue_id = json[:queue_id]
                last_event_id = json[:last_event_id]
        end

        reply {queue_id, last_event_id}
    end
end
