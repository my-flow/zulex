require Logger

defmodule Processor.Base do

    defmacro __using__(_) do
        quote do
            use HTTPotion.Base

            def base_url do
                "https://api.zulip.com/v1/"
            end

            def process_request_headers(headers) do
                Dict.put headers, :"User-Agent", "ZulEx"
            end

            def process_response_body(body) do
                :jsx.decode to_string(body), [{:labels, :atom}]
            end

            def process_response_chunk(chunk) do
                :jsx.decode to_string(chunk), [{:labels, :atom}]
            end
        end
    end
end
