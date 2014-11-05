import Logger

defmodule ArchiveHandler do
    use GenEvent


    def init(_) do
        stream = File.stream!(create_latest_log_file, [:append, {:encoding, :utf8}])
        Collectable.into(stream)
    end


    def handle_event(new_messages, fun) when is_list(new_messages) do
        Enum.each(new_messages, &(fun.(:ok, {:cont, JSEX.encode!(&1) <> "\n"})))
        {:ok, fun}
    end


    def terminate(reason, fun) do
        fun.(:ok, :done)
    end


    @spec create_latest_log_file :: binary
    defp create_latest_log_file do
        filename = ArchiveHelper.get_log_file_name
        dirname  = ArchiveHelper.get_log_path
        linkname = ArchiveHelper.get_link_to_latest_log_file

        File.mkdir_p!(dirname)
        File.touch!(filename)

        case File.rm!(linkname) do
            {:error, reason} ->
                Logger.debug("#{__MODULE__}: Removing symbolic link failed with reason #{inspect reason}")
            :ok ->
                :ok
        end

        case File.ln_s(Path.basename(filename), linkname) do
            {:error, reason} ->
                Logger.debug("#{__MODULE__}: Creating symbolic link failed with reason #{inspect reason}")
            :ok ->
                :ok
        end
        filename
    end
end
