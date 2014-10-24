import Logger

defmodule MessageConsoleHandler do
    use GenEvent

    def handle_event(new_messages, context) when is_list(new_messages) do
        {_, new_context} = Enum.map_reduce(
            new_messages,
            context,
            fn m, acc ->
                c = build_context(m)
                if (c != acc) do
                    display_context(m)
                end
                display_message(m)
                {m, c}
            end
        )
        {:ok, new_context}
    end


    defp display_context(m) do
        Logger.debug("███ #{m[:display_recipient]} » #{m[:subject]}")
    end


    defp display_message(m) do
        Logger.log(
            get_level(m[:sender_email] <> m[:subject]),
            "#{m[:sender_short_name]}: #{m[:content]}"
        )
    end


    defp build_context(m) do
        m[:display_recipient] <> m[:subject]
    end


    defp get_level(string) do
        all_levels = [:error, :warn, :info]
        keys = Enum.reduce(
            String.codepoints(string),
            0, # acc
            fn << c :: utf8 >>, acc ->
                rem(c + acc, Enum.count(all_levels))
            end
        )
        Enum.fetch!(all_levels, keys)
    end
end
