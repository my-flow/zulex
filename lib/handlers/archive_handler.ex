defmodule ArchiveHandler do
    use GenEvent

    import Logger


    def init(username) do
        stream = File.stream!(create_latest_log_file!(username), [:append, {:encoding, :utf8}])
        Collectable.into(stream)
    end


    def handle_event(new_messages, fun) when is_list(new_messages) do
        Enum.each(new_messages, &(fun.(:ok, {:cont, JSEX.encode!(&1) <> "\n"})))
        {:ok, fun}
    end


    def terminate(_, fun) do
        fun.(:ok, :done)
    end


    @spec create_latest_log_file!(binary) :: binary
    defp create_latest_log_file!(username) do
        filename = ArchiveHelper.get_log_file_name(username)
        dirname  = ArchiveHelper.get_expanded_log_path(username)
        linkname = ArchiveHelper.get_link_to_latest_log_file(username)

        File.mkdir_p!(dirname)
        File.touch!(filename)

        case File.rm(linkname) do
            {:error, reason} ->
                debug("#{__MODULE__}: Removing symbolic link failed with reason #{inspect reason}")
            :ok ->
                :ok
        end

        case File.ln_s(Path.basename(filename), linkname) do
            {:error, reason} ->
                debug("#{__MODULE__}: Creating symbolic link failed with reason #{inspect reason}")
            :ok ->
                :ok
        end
        filename
    end
end
