import Logger
import Supervisor.Spec

defmodule ZulEx do
    use Application

    def start(_type, _args) do
        Task.async(fn -> read_messages(:ignore) end)
        children = [
            worker(SessionHandler, [[name: :sessionHandler]])
        ]
        Supervisor.start_link(children, [strategy: :one_for_one, name: ZulEx.Supervisor])
    end


    def read_messages(handle_undefined \\ :ask) do
        credentials = get_credentials(handle_undefined)
        if credentials do
            unless Process.whereis(:queueClient) do
                Supervisor.start_child(
                    ZulEx.Supervisor,
                    worker(QueueClient, [credentials, [name: :queueClient]])
                )
            end
            QueueClient.register_queue(:queueClient)
        end
    end


    def whois(user, handle_undefined \\ :ask)


    def whois(user, handle_undefined) when is_binary(user) do
        _whois(user, handle_undefined)
    end


    def whois(regex = %Regex{}, handle_undefined) do
        _whois(regex, handle_undefined)
    end


    # private functions

    defp _whois(user, handle_undefined) do
        credentials = get_credentials(handle_undefined)
        unless Process.whereis(:userClient) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(UserClient, [credentials, [name: :userClient]])
            )
        end
        UserClient.find_users(:userClient, user)
    end


    defp get_credentials(handle_undefined) do
        unless Process.whereis(:sessionHandler) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(SessionHandler, [[name: :sessionHandler]])
            )
        end
        SessionHandler.authenticate(:sessionHandler, handle_undefined)
    end
end
