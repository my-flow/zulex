defmodule DisplayHanderPrivateMessageTest do
    use ExUnit.Case

    test "private messages" do
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
                },
                %{
                    :domain => "example.com", 
                    :email => "mail1@example.com", 
                    :full_name => "sender1's full name", 
                    :id => 1, 
                    :is_mirror_dummy => false,
                    :short_name => "sender1"
                }
            ], 
            :subject => "", 
            :timestamp => 0, 
            :id => 0,

            :sender_id => 0,
            :sender_short_name => "sender0", 
            :content => "Well there's a somewhat better answer"
        }

        second = %{
            :type => "private",
            :display_recipient => [
                %{
                    :domain => "example.com",
                    :email => "mail0@example.com", 
                    :full_name => "Sender0's full name", 
                    :id => 0, 
                    :is_mirror_dummy => false, 
                    :short_name => "sender0"
                },
                %{
                    :domain => "example.com", 
                    :email => "mail1@example.com", 
                    :full_name => "sender1's full name", 
                    :id => 1, 
                    :is_mirror_dummy => false, 
                    :short_name => "sender1"
                }
            ], 
            :subject => "",
            :timestamp => 1, 
            :id => 1,

            :sender_id => 1,
            :sender_short_name => "sender1",
            :content => "Funny enough your private message led to another exception :D"
        }

        assert [first, second] == DisplayHandler.sort_messages([first, second], true)
        {:ok, _} = DisplayHandler.handle_event([first, second], %{:opts => [resort: true], :context => ""})
    end
end
