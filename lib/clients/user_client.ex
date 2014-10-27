defmodule UserClient do
    use ExActor.GenServer

    def start_link(credentials = %ZulipAPICredentials{}, opts) do
        GenServer.start_link(__MODULE__, credentials, opts)
    end


    defcall find_users(user), state: %ZulipAPICredentials{key: key, email: email} do
        HTTPotion.start
        ibrowse = Dict.merge [basic_auth: {email, key}], Application.get_env(:zulex, :ibrowse, [])

        try do
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
                    reply {:error, "Request failed with HTTP status code #{status_code}."}
                json[:result] == "error" ->
                    reply {:error, "Received the following error message from Zulip server: \"#{json[:msg]}\""}
                true ->
                    reply filter_users(json[:members], user)
            end

        rescue
            e in HTTPotion.HTTPError -> reply {:error, e.message}
        end
    end


    # private functions

    defp filter_users(members, user) when is_binary(user) do
        filter_users(members, Regex.compile!(user, "iu"))
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
