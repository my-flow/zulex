import Logger
import Supervisor.Spec

defmodule ZulEx do
    use Application

    def start(_type, _args) do
        Task.async(fn -> read_messages(:ignore) end)
        children = [
            worker(StateHandler, [[name: :stateHandler, restart: :transient]])
        ]
        Supervisor.start_link(children, [strategy: :one_for_one, name: ZulEx.Supervisor])
    end


    def read_messages(handle_undefined \\ :ask) do
        credentials = get_credentials(handle_undefined)
        if credentials do
            if Process.whereis(:queueClient) do
                :ok = Supervisor.terminate_child(ZulEx.Supervisor, QueueClient)
                :ok = Supervisor.delete_child(ZulEx.Supervisor, QueueClient)
            end
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(QueueClient, [credentials, [name: :queueClient, restart: :transient]])
            )
        end
    end


    def read_subscriptions(name \\ :all, handle_undefined \\ :ask)


    def read_subscriptions(name, handle_undefined) when is_binary(name) or is_atom(:all) do
        _read_subscriptions(name, handle_undefined)
    end


    def read_subscriptions(regex = %Regex{}, handle_undefined) do
        _read_subscriptions(regex, handle_undefined)
    end


    def read_users(handle_undefined \\ :ask) do
        _read_users(:all, handle_undefined)
    end


    def whois(user, handle_undefined \\ :ask)


    def whois(user, handle_undefined) when is_binary(user) or is_atom(user) do
        _read_users(user, handle_undefined)
    end


    def whois(regex = %Regex{}, handle_undefined) do
        _read_users(regex, handle_undefined)
    end


    # private functions

    defp _read_subscriptions(name, handle_undefined) do
        credentials = get_credentials(handle_undefined)
        if credentials do
            unless Process.whereis(:subscriptionClient) do
                Supervisor.start_child(
                    ZulEx.Supervisor,
                    worker(SubscriptionClient, [credentials, [name: :subscriptionClient, restart: :transient]])
                )
            end
            SubscriptionClient.read_subscriptions(:subscriptionClient, name)
        end
    end


    defp _read_users(user, handle_undefined) do
        credentials = get_credentials(handle_undefined)
        if credentials do
            unless Process.whereis(:userClient) do
                Supervisor.start_child(
                    ZulEx.Supervisor,
                    worker(UserClient, [credentials, [name: :userClient, restart: :transient]])
                )
            end
            UserClient.find_users(:userClient, user)
        end
    end


    defp get_credentials(handle_undefined) do
        unless Process.whereis(:stateHandler) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(StateHandler, [[name: :stateHandler, restart: :transient]])
            )
        end
        StateHandler.authenticate(handle_undefined)
    end
end
