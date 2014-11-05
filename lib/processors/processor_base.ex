defmodule Processor.Base do

    defmacro __using__(_) do
        quote do
            use HTTPotion.Base
            import JSEX

            def base_url do
                "https://api.zulip.com/v1/"
            end

            def process_request_headers(headers) do
                Dict.put headers, :"User-Agent", "ZulEx"
            end

            def process_response_body(body) when is_list(body) do
                process_response_body(to_string(body))
            end

            def process_response_body(body) when is_binary(body) do
                if JSEX.is_json? body do
                    JSEX.decode! body, [labels: :atom]
                else
                    body
                end
            end

            def process_response_chunk(chunk) when is_list(chunk) do
                process_response_body(chunk)
            end

            def process_response_chunk(chunk) do
                chunk
            end
        end
    end
end
