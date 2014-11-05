defmodule DisplayHanderSingletonMessageTest do
    use ExUnit.Case

    test "private singleton messages" do
        first = %{
            :type => "private",
            :display_recipient => [
                %{
                    :domain => "example.com", 
                    :email => "mail0@example.com", 
                    :full_name => "Sender0's full name", 
                    :id => 0, 
                    :is_mirror_dummy => false, 
                    :short_name => "sender1"
                }
            ], 
            :subject => "", 
            :timestamp => 0, 

            :sender_id => 0,
            :sender_short_name => "sender0", 
            :content => "Well there's a somewhat better answer"
        }

        assert [first] == DisplayHandler.sort_messages([first], true)
        {:ok, _} = DisplayHandler.handle_event([first], %{:opts => [resort: true], :context => ""})
    end
end
