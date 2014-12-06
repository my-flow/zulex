import Logger

defmodule SessionManager do
    use ExActor.Strict, export: :SessionManager


    defstart start_link do
        Logger.info "Starting #{inspect __MODULE__}"
        initial_state nil
    end


    @spec authenticate(atom) :: term
    def authenticate(handle_undefined \\ :ignore) do
        result = __MODULE__.authenticate_user
        case result do
            nil -> __MODULE__.update_credentials(read_or_ask_for_credentials(handle_undefined))
            %ZulipAPICredentials{}  -> result
        end
    end


    defcall authenticate_user, state: credentials do
        reply credentials
    end


    defcall update_credentials(credentials) do
        set_and_reply credentials, credentials
    end


    defp read_or_ask_for_credentials(handle_undefined) do
        credentials = get_stored_api_credentials()
        case credentials do
            %ZulipAPICredentials{} ->
                credentials
            _ when handle_undefined == :ignore ->
                nil
            _ -> 
                email = String.to_char_list String.strip IO.gets "Please enter your Zulip email address: "
                key   = String.to_char_list String.strip IO.gets "Please enter your Zulip API key      : "
                %ZulipAPICredentials{key: key, email: email}
        end
    end


    defp get_stored_api_credentials do
        basic_auth = Dict.get(Application.get_env(:zulex, :ibrowse, []), :basic_auth)
        if basic_auth && tuple_size(basic_auth) == 2, do: {email, key} = basic_auth

        if !email || !key do
            email = System.get_env("ZULIP_USERNAME")
            key   = System.get_env("ZULIP_API_KEY")
        end

        email = if is_binary(email), do: String.to_char_list(email), else: email
        key   = if is_binary(key),   do: String.to_char_list(key),   else: key

        if email && key,
            do: %ZulipAPICredentials{email: email, key: key},
        else:
            nil
    end
end
