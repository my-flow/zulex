defmodule ArchiveHelper do
    use Timex

    @date_format "%Y-%m-%d.log"
    @log_file_format ~r/\d{4}-\d{2}-\d{2}\.log$/


    @spec get_link_to_latest_log_file(binary) :: binary
    def get_link_to_latest_log_file(username) do
        Path.join(get_log_path!(username) ++ ["latest"]) |> Path.expand
    end


    @spec get_log_file_name(binary) :: binary
    def get_log_file_name(username) do
        Path.join(get_log_path!(username) ++ [DateFormat.format!(Date.local, @date_format, :strftime)]) |> Path.expand
    end


    @spec get_expanded_log_path(binary) :: binary
    def get_expanded_log_path(username) do
        Path.join(get_log_path!(username)) |> Path.expand
    end


    @spec get_all_log_files!(binary) :: [binary]
    def get_all_log_files!(username) do
        File.ls!(get_expanded_log_path(username))
            |> Enum.filter(&(Regex.match?(@log_file_format, &1)))
            |> Enum.sort
            |> Enum.map(&(Path.expand(Path.join(get_log_path!(username) ++ [&1]))))
    end


    @spec get_log_path!(binary) :: [binary]
    defp get_log_path!(username) do
        [System.user_home!, ".zulex", username]
    end

end
