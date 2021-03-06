
defmodule ZulEx do
    use Application
    import Supervisor.Spec
    import Logger


    def start(_type, _args) do
        %{} = Task.async(fn -> read_messages(:ignore) end)
        Supervisor.start_link([], [strategy: :one_for_one, name: ZulEx.Supervisor])
    end


    def read_messages(handle_undefined \\ :ask) do
        credentials = authenticate(handle_undefined)
        if credentials do
            case Process.whereis(:Reader) do
                nil -> Supervisor.start_child(
                    ZulEx.Supervisor,
                    supervisor(Reader, [credentials], restart: :transient)
                )
                _ -> debug "#{__MODULE__}: Reader is already registered."
            end
            Reader.restart_connector
        end
    end


    def mute_messages do
        Reader.mute_messages
    end


    def unmute_messages do
        Reader.unmute_messages
    end


    def replay_messages(options \\ []) do
        case Process.whereis(:ReplayClient) do
            nil ->
                redis_connection_string = Application.get_env(:zulex, :redis_connection_string)
                worker = case redis_connection_string do
                    nil -> worker(ReplayFileClient,  [], restart: :temporary)
                    _   -> worker(ReplayRedisClient, [redis_connection_string], restart: :temporary)
                end

                Supervisor.start_child(ZulEx.Supervisor, worker)
            _ -> debug "#{__MODULE__}: ReplayClient is already registered."
        end
        GenServer.call(:ReplayClient, {:replay_messages, options})
    end


    def read_subscriptions(name \\ :all)


    @spec read_subscriptions(binary | atom) :: [binary]
    def read_subscriptions(name) when is_binary(name) or is_atom(:all) do
        _read_subscriptions(name)
    end


    @spec read_subscriptions(%Regex{}) :: [binary]
    def read_subscriptions(regex = %Regex{}) do
        _read_subscriptions(regex)
    end


    @spec read_users :: [map]
    def read_users do
        _read_users(:all)
    end


    @spec whois(binary | atom) :: [map]
    def whois(user) when is_binary(user) or is_atom(user) do
        _read_users(user)
    end

    def whois(regex = %Regex{}) do
        _read_users(regex)
    end


    # private functions

    @spec _read_subscriptions(term) :: [binary]
    defp _read_subscriptions(name) do
        credentials = authenticate(:ask)
        case Process.whereis(:SubscriptionClient) do
            nil -> Supervisor.start_child(
                        ZulEx.Supervisor,
                        worker(SubscriptionClient, [credentials], restart: :temporary)
                   )
            _ -> debug "#{__MODULE__}: SubscriptionClient is already registered."
        end
        SubscriptionClient.read_subscriptions(name)
    end


    @spec _read_users(term) :: [map]
    defp _read_users(user) do
        credentials = authenticate(:ask)
        case Process.whereis(:UserClient) do
            nil -> Supervisor.start_child(
                        ZulEx.Supervisor,
                        worker(UserClient, [credentials], restart: :temporary)
                   )
            _ -> debug "#{__MODULE__}: UserClient is already registered."
        end
        UserClient.find_users(user)
    end


    @spec authenticate(atom) :: term
    defp authenticate(handle_undefined) do
        case Process.whereis(:SessionManager) do
            nil -> Supervisor.start_child(
                        ZulEx.Supervisor,
                        worker(SessionManager, [], restart: :transient)
                   )
            _ -> debug "#{__MODULE__}: SessionManager is already registered."
        end
        credentials = SessionManager.authenticate(handle_undefined)
        SessionManager.update_credentials(credentials)
    end
end
