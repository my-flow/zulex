import Logger

defmodule UserClient do
    use ExActor.Strict, export: :UserClient


    defstart start_link(credentials = %ZulipAPICredentials{}) do
        Logger.info "Starting #{inspect __MODULE__}"
        initial_state credentials
    end


    defcall find_users(user), state: %ZulipAPICredentials{key: key, email: email} do

        HTTPotion.start
        ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

        response = UserProcessor.get(
            "",
            [], # empty headers
            [
                ibrowse: ibrowse,
                timeout: 600_000
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
                reply filter_users(json[:members], user)
        end
    end


    # private functions

    defp filter_users(members, user) when is_binary(user) or is_atom(user) do
        regex = case user do
            :all -> ".*"
            _ -> user
        end
        filter_users(members, Regex.compile!(regex, "iu"))
    end


    defp filter_users(members, regex = %Regex{}) do
        Enum.filter(
            members,
            fn m ->
                Enum.any?(Dict.values(m), fn v -> is_binary(v) && Regex.match?(regex, v) end)
            end
        )
    end
end
