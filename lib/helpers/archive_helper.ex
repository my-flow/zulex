import Logger

defmodule ArchiveHelper do
    use Timex


    @log_path [
        System.user_home!,
        ".zulex",
        "archive"
    ]

    @date_format "%Y-%m-%d.log"
    @log_file_format ~r/\d{4}-\d{2}-\d{2}\.log$/


    @spec get_link_to_latest_log_file :: binary
    def get_link_to_latest_log_file do
        Path.expand(Path.join(@log_path ++ ["latest"]))
    end


    @spec get_log_file_name :: binary
    def get_log_file_name do
        Path.expand(Path.join(@log_path ++ [DateFormat.format!(Date.local, @date_format, :strftime)]))
    end


    @spec get_log_path :: binary
    def get_log_path do
        Path.expand(Path.join(@log_path))
    end


    @spec get_all_log_files! :: [binary]
    def get_all_log_files! do
        Enum.map(
            Enum.sort(
                Enum.filter(
                    File.ls!(get_log_path), 
                    &(Regex.match?(@log_file_format, &1))
                )
            ),
            &(Path.expand(Path.join(@log_path ++ [&1])))
        )
    end
end
