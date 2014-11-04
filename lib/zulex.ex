import Logger
import Supervisor.Spec

defmodule ZulEx do
    use Application

    def start(_type, _args) do
        Task.async(fn -> read_messages(:ignore) end)
        Supervisor.start_link([], [strategy: :one_for_one, name: ZulEx.Supervisor])
    end


    def read_messages(handle_undefined \\ :ask) do
        credentials = authenticate(handle_undefined)
        if credentials do
            unless Process.whereis(:Reader) do
                Supervisor.start_child(
                    ZulEx.Supervisor,
                    supervisor(Reader, [credentials], restart: :transient)
                )
            end
            Reader.restart_connector
        end
    end


    def pause_messages do
        Reader.stop_connector
    end


    def read_subscriptions(name \\ :all)


    def read_subscriptions(name) when is_binary(name) or is_atom(:all) do
        _read_subscriptions(name)
    end


    def read_subscriptions(regex = %Regex{}) do
        _read_subscriptions(regex)
    end


    def read_users do
        _read_users(:all)
    end


    def whois(user) when is_binary(user) or is_atom(user) do
        _read_users(user)
    end


    def whois(regex = %Regex{}) do
        _read_users(regex)
    end


    # private functions

    defp _read_subscriptions(name) do
        credentials = authenticate(:ask)
        unless Process.whereis(:SubscriptionClient) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(SubscriptionClient, [credentials], restart: :temporary)
            )
        end
        SubscriptionClient.read_subscriptions(name)
    end


    defp _read_users(user) do
        credentials = authenticate(:ask)
        unless Process.whereis(:UserClient) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(UserClient, [credentials], restart: :temporary)
            )
        end
        UserClient.find_users(user)
    end


    defp authenticate(handle_undefined) do
        unless Process.whereis(:SessionManager) do
            Supervisor.start_child(
                ZulEx.Supervisor,
                worker(SessionManager, [], restart: :transient)
            )
        end
        credentials = SessionManager.authenticate(handle_undefined)
        SessionManager.update_credentials(credentials)
    end
end
