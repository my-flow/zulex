import Logger

defmodule MessageLogger do
    use GenEvent

    @colors [
        IO.ANSI.blue,
        IO.ANSI.bright,
        IO.ANSI.cyan,
        IO.ANSI.green,
        IO.ANSI.magenta,
        IO.ANSI.white,
        IO.ANSI.yellow
    ]


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
        groups = Enum.into(
            Enum.map(
                Enum.group_by(messages, &build_context/1),
                fn {k, ms} -> {k, Enum.max(Enum.map(ms, &(&1[:timestamp])))} end
            ),
            %{}
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
        r = m[:display_recipient]
        case r do
            [head|_]            -> line = "You and #{head[:full_name]}"
            _ when is_binary(r) -> line = "#{r} » #{m[:subject]}"
        end
        IO.puts("███ #{line}")
    end


    defp display_message(m) do
        IO.puts(
            get_color(Integer.to_string(m[:sender_id]) <> m[:subject]) <>
            "#{m[:sender_short_name]}: #{m[:content]}" <>
            IO.ANSI.default_background <> IO.ANSI.default_color
        )
    end


    defp build_context(m) do
        inspect(m[:display_recipient]) <> " " <> inspect(m[:subject])
    end


    defp get_color(string) do
        if IO.ANSI.enabled? do
            count = Enum.count(@colors)
            keys = Enum.reduce(
                String.codepoints(string),
                0, # acc
                fn << c :: utf8 >>, acc ->
                    rem(c + acc, count)
                end
            )
            Enum.fetch!(@colors, keys)
        else
            ""
        end
    end
end
