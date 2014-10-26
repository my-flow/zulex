defmodule UserProcessor do
    use Processor.Base

    def process_url(_) do
        base_url <> "users"
    end
end
