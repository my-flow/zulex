defmodule ArchiveRedisHandler do
    use GenEvent


    def init(redis_connection_string, username) do
        {:ok, {redis_connection_string, username}}
    end


    def handle_event(new_messages, state = {redis_connection_string, username}) when is_list(new_messages) do
        new_messages = new_messages |> Enum.map(&JSX.encode!(&1))
        ArchiveRedisHelper.set(redis_connection_string, username, new_messages)
        {:ok, state}
    end


    def handle_event(new_messages, state = [redis_connection_string, username]) when is_list(new_messages) do
        new_messages = new_messages |> Enum.map(&JSX.encode!(&1))
        ArchiveRedisHelper.set(redis_connection_string, username, new_messages)
        {:ok, state}
    end

end
