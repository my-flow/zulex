defmodule ArchiveRedisHelper do
    use Exredis


    def set(redis_connection_string, username, messages) when is_list(messages) do
        Exredis.start_using_connection_string(redis_connection_string)
            |> query ["LPUSH", "zulex:#{username}" | messages]
    end


    def get(redis_connection_string, username) do
        Exredis.start_using_connection_string(redis_connection_string)
            |> query ["LRANGE", "zulex:#{username}", 0, -1]
    end


    def delete(redis_connection_string, username) do
        Exredis.start_using_connection_string(redis_connection_string)
            |> query ["DEL", "zulex:#{username}"]
    end

end
