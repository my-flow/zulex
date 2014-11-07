defmodule DisplayHandlerUnicodeTest do
    use ExUnit.Case

    test "unicode messages" do
        first = %{
                :display_recipient => "test-stream",
                :subject => "äöü Unicode",
                :timestamp => 0,
                :id => 0,

                :sender_id => 0,
                :sender_short_name => "sender0",
                :content => "Anyone up for a quick bite? I'm starving... "
        }

        second = %{
                :display_recipient => "455 Broadway",
                :subject => "Monads!",
                :timestamp => 1,
                :id => 1,

                :sender_id => 1,
                :sender_short_name => "sender1",
                :content => "I'm going to grab some lunch. Monads after?"
        }

        third = %{
                :display_recipient => "test-stream",
                :subject => "äöü Unicode",
                :timestamp => 2,
                :id => 2,

                :sender_id => 2,
                :sender_short_name => "sender2",
                :content => "I also hunger."
        }

        assert [second, first, third] == DisplayHandler.sort_messages([first, second, third], true)
        {:ok, _} = DisplayHandler.handle_event([first, second, third], %{:opts => [resort: true], :context => ""})
    end
end
