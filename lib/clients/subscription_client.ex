import Logger

defmodule SubscriptionClient do
    use ExActor.Strict, export: :SubscriptionClient


    defstart start_link(credentials = %ZulipAPICredentials{}) do
        Logger.info "Starting #{inspect __MODULE__}"
        initial_state credentials
    end


    defcall read_subscriptions(name), state: %ZulipAPICredentials{key: key, email: email} do

        HTTPotion.start
        ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

        response = SubscriptionProcessor.get(
            "",
            [], # empty headers
            [
                ibrowse: ibrowse
            ]
        )

        %HTTPotion.Response{body: json, status_code: status_code} = response
        cond do
            !HTTPotion.Response.success?(response) ->
                msg = "#{__MODULE__}: Request failed with HTTP status code #{status_code}."
                Logger.error(msg)
                raise RuntimeError, message: msg
            json[:result] == "error" ->
                Logger.error(json[:msg])
                reply {:error, json[:msg]}
            true ->
                reply filter_subscriptions(json[:subscriptions], name)
        end
    end


    # private functions

    defp filter_subscriptions(subscriptions, name) when is_binary(name) or is_atom(name) do
        regex = case name do
            :all -> ".*"
            _ -> name
        end
        filter_subscriptions(subscriptions, Regex.compile!(regex, "iu"))
    end


    defp filter_subscriptions(subscriptions, regex = %Regex{}) do
        Enum.filter(
            reduce_subscriptions(subscriptions),
            fn name ->
                is_binary(name) && Regex.match?(regex, name)
            end
        )
    end


    defp reduce_subscriptions(subscriptions) when is_list(subscriptions) do
        Enum.map(subscriptions, &Dict.get(&1, :name))
    end
end
