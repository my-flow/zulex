defmodule ArchiveHelper do
    use Timex


    @log_path [
        System.user_home!,
        ".zulex",
        "archive"
    ]


    @spec get_link_to_latest_log_file :: binary
    def get_link_to_latest_log_file do
        Path.expand(Path.join(@log_path ++ ["latest"]))
    end


    @spec get_log_file_name :: binary
    def get_log_file_name do
        Path.expand(Path.join(@log_path ++ [DateFormat.format!(Date.local, "%Y-%m-%d.log", :strftime)]))
    end


    @spec get_log_path :: binary
    def get_log_path do
        Path.expand(Path.join(@log_path))
    end
end
