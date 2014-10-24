import Logger

defmodule MessageLogger do
    use GenEvent

    def handle_event(new_messages, context) when is_list(new_messages) do
        {_, new_context} = Enum.map_reduce(
            sort_messages(new_messages),
            context,
            fn m, acc ->
                c = build_context(m)
                unless c == acc, do: display_context(m)
                display_message(m)
                {m, c}
            end
        )
        {:ok, new_context}
    end


    def sort_messages(messages) when is_list(messages) do
        groups = Enum.map(
            Enum.group_by(messages, &build_context/1),
            fn {k, ms} -> {k, Enum.max(Enum.map(ms, &(&1[:timestamp])))} end
        )
        Enum.sort(
            messages,
            &(
                Dict.get(groups, build_context(&1)) <= Dict.get(groups, build_context(&2))
                && &1[:timestamp] <= &2[:timestamp]
            )
        )
    end


    defp display_context(m) do
        Logger.debug("███ #{m[:display_recipient]} » #{m[:subject]}")
    end


    defp display_message(m) do
        Logger.log(
            get_level(Integer.to_string(m[:sender_id]) <> m[:subject]),
            "#{m[:sender_short_name]}: #{m[:content]}"
        )
    end


    defp build_context(m) do
        String.to_atom(m[:display_recipient] <> " " <> m[:subject])
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
