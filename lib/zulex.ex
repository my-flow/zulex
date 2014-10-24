import Logger
import Supervisor.Spec

defmodule ZulEx do
    use Application

    def start(_type, _args) do
        opts = [strategy: :one_for_one, name: ZulEx.Supervisor]
        Task.async(fn -> ZulEx.auto_initialize end)
        Supervisor.start_link([], opts)
    end


    def auto_initialize do
        case get_api_credentials do
            %ZulipAPICredentials{} -> start_child(get_api_credentials)
            _ -> Logger.warn "Zulip credentials were not found in environment.\n" <>
                    "Please execute #{__MODULE__}.connect/0 to enter your Zulip credentials on the prompt."
        end
    end


    def connect do
        email = String.strip IO.gets "Please enter your Zulip email address: "
        key   = String.strip IO.gets "Please enter your Zulip API key      : "
        start_child(%ZulipAPICredentials{email: email, key: key})
    end


    defp start_child(credentials = %ZulipAPICredentials{}) do
        {:ok, pid} = QueueClient.start_link(credentials, [name: :queueClient])
        {queue_id, last_event_id} = QueueClient.register_queue(pid)

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
        MessageClient.request_new_messages(:messageClient, MessageLogger, "")
    end


    defp get_api_credentials do
        email = System.get_env("ZULIP_USERNAME")
        key   = System.get_env("ZULIP_API_KEY")

        if (email && key) do
            %ZulipAPICredentials{
                email: email,
                key:   key
            }
        else
            nil
        end
    end
end
