import Logger
import Supervisor.Spec

defmodule QueueClient do
    use ExActor.GenServer

    @default_event_id -1

    def start_link(credentials = %ZulipAPICredentials{}, opts) do
        GenServer.start_link(__MODULE__, {@default_event_id, credentials}, opts)
    end


    defcall register_queue, state: {_, credentials = %ZulipAPICredentials{key: key, email: email}} do
        HTTPotion.start
        ibrowse = [
            proxy_host: String.to_char_list("localhost"),
            proxy_port: 8080,
            basic_auth: {
                String.to_char_list(email),
                String.to_char_list(key)
            }
        ]

        response = QueueProcessor.post(
            "",
            URI.encode_query(%{"event_types" => :jsx.encode(["message"])}),
            [{"Content-Type", "application/x-www-form-urlencoded"}],
            [ibrowse: ibrowse]
        )

        %HTTPotion.Response{body: json, status_code: status_code} = response
        cond do
            !HTTPotion.Response.success?(response) ->
                reply {:error, "Request failed with HTTP status code #{status_code}."}
            json[:result] == "error" ->
                reply {:error, "Received the following message from Zulip server: \"#{json[:msg]}\""}
            true ->
                reply request_messages(json[:queue_id], json[:last_event_id], credentials)
        end

        reply :ok
    end


    defcall update_last_event_id(last_event_id), state: {_, credentials} do
        set_and_reply {last_event_id, credentials}, last_event_id
    end


    definfo {:DOWN, _, :process, pid, _}, state: {last_event_id, _} do
        Supervisor.restart_child(ZulEx.Supervisor, pid)
        Process.monitor(:messageClient)
        MessageClient.request_new_messages(:messageClient, MessageLogger, "", last_event_id)
        noreply
    end


    # private functions

    defp request_messages(queue_id, last_event_id, credentials) do
        Supervisor.start_child(
            ZulEx.Supervisor,
            worker(
                MessageClient, [
                    queue_id,
                    last_event_id,
                    credentials,
                    [name: :messageClient]
                ]
            )
        )
        Process.monitor(:messageClient)
        MessageClient.request_new_messages(:messageClient, MessageLogger, "", last_event_id)
    end
end
