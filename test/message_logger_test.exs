defmodule MessageLoggerTest do
    use ExUnit.Case

    test "sorting of messages" do
        first = [
                display_recipient: "food",
                subject: "lunch",
                timestamp: 0,

                sender_id: 0,
                sender_short_name: "sender0",
                content: "Anyone up for a quick bite? I'm starving... "
        ]

        second = [
                display_recipient: "455 Broadway",
                subject: "Monads!",
                timestamp: 1,

                sender_id: 1,
                sender_short_name: "sender1",
                content: "I'm going to grab some lunch. Monads after?"
        ]

        third = [
                display_recipient: "food",
                subject: "lunch",
                timestamp: 2,

                sender_id: 2,
                sender_short_name: "sender2",
                content: "I also hunger."
        ]

        assert [second, first, third] == MessageLogger.sort_messages([first, second, third])
    end
end
