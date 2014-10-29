import Logger
import Supervisor.Spec

defmodule QueueClient do
    use ExActor.Tolerant

    @default_event_id -1


    def start_link(credentials = %ZulipAPICredentials{}, opts) do
        GenServer.start_link(__MODULE__, {@default_event_id, credentials}, opts)
    end


    defcall register_queue, state: {_, credentials = %ZulipAPICredentials{key: key, email: email}} do
        HTTPotion.start
        ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

        try do
            response = QueueProcessor.post(
                "",
                URI.encode_query(%{"event_types" => JSEX.encode!(["message"])}),
                [{"Content-Type", "application/x-www-form-urlencoded"}],
                [ibrowse: ibrowse]
            )

            %HTTPotion.Response{body: json, status_code: status_code} = response
            cond do
                !HTTPotion.Response.success?(response) ->
                    msg = "#{__MODULE__}: Request failed with HTTP status code #{status_code}."
                    Logger.error(msg)
                    reply {:error, msg}
                json[:result] == "error" ->
                    Logger.error(json[:msg])
                    reply {:error, json[:msg]}
                true ->
                    reply request_messages(json[:queue_id], json[:last_event_id], credentials)
            end

        rescue
            e in HTTPotion.HTTPError ->
                Logger.error "#{__MODULE__}: #{e.message}"
                reply {:error, e.message}
        end
    end


    defcall update_last_event_id(last_event_id), state: {_, credentials} do
        set_and_reply {last_event_id, credentials}, last_event_id
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


    # private functions

    defp request_messages(queue_id, last_event_id, credentials) do
        unless Process.whereis(:messageClient) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(MessageClient, [MessageLogger, "", credentials, [name: :messageClient]])
            )
            Process.monitor(:messageClient)
        end
        MessageClient.set_parameters(:messageClient, queue_id, last_event_id)
        MessageClient.request_new_messages(:messageClient)
    end
end
