defmodule ArchiveRedisHandlerTest do
  use ExUnit.Case

  @redis_connection_string "redis://127.0.0.1:6379"
  @username 'username'


  test "start" do
    {:ok, pid} = GenEvent.start_link(name: :e1)
    assert :ok == GenEvent.add_handler(:e1, ArchiveRedisHandler, [@redis_connection_string, "username"])
    ArchiveRedisHelper.delete(@redis_connection_string, @username)
    Process.exit(pid, :shutdown)
  end


  test "send empty messages" do
    {:ok, pid} = GenEvent.start_link(name: :e2)
    assert :ok == GenEvent.add_handler(:e2, ArchiveRedisHandler, [@redis_connection_string, "username"])
    assert :ok == GenEvent.notify(:e2, [])
    ArchiveRedisHelper.delete(@redis_connection_string, @username)
    Process.exit(pid, :shutdown)
  end


  test "send unicode message" do
    message = %{
      :display_recipient => "test-stream",
      :subject => "äöü Unicode",
      :timestamp => 0,
      :id => 0,

      :sender_id => 0,
      :sender_short_name => "sender0",
      :content => "Anyone up for a quick bite? I'm starving... "
    }

    {:ok, pid} = GenEvent.start_link(name: :e2)
    assert :ok == GenEvent.add_handler(:e2, ArchiveRedisHandler, [@redis_connection_string, "username"])
    assert :ok == GenEvent.notify(:e2, [message])
    {:ok, _} = ArchiveRedisHandler.handle_event([message], [@redis_connection_string, @username])

    ArchiveRedisHelper.delete(@redis_connection_string, @username)
    Process.exit(pid, :shutdown)
  end


end