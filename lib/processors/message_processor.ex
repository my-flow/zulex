defmodule MessageProcessor do
    use Processor.Base

    def process_url(query_string) do
        base_url <> "events?" <> query_string
    end
end
