defmodule QueueProcessor do
    use Processor.Base

    def process_url(_) do
        base_url <> "register"
    end

end
