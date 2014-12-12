defmodule ReplayRedisClientTest do
  use ExUnit.Case

  @redis_connection_string "redis://127.0.0.1:6379"


  setup do
    Application.put_env(:zulex, :redis_connection_string, "redis://127.0.0.1:6379")
    case StateManager.start_link(%ZulipAPICredentials{:key => "key", :email => "email"}) do
      {:ok, pid} -> on_exit fn -> Process.exit(pid, :shutdown) end
      _          -> on_exit fn -> end
    end
  end


  test "start" do
    {:ok, pid} = ReplayRedisClient.start_link(@redis_connection_string)
    assert Process.alive?(pid)
  end


  test "replay messages with count 0" do
    {:ok, pid} = ReplayRedisClient.start_link(@redis_connection_string)
    assert :ok == GenServer.call(pid, {:replay_messages, [count: 0]})
  end


  test "replay messages with count 1" do
    {:ok, pid} = ReplayRedisClient.start_link(@redis_connection_string)
    assert :ok == GenServer.call(pid, {:replay_messages, [count: 1]})
  end


  test "replay messages and count with filter" do
    {:ok, pid} = ReplayRedisClient.start_link(@redis_connection_string)
    assert :ok == GenServer.call(
      pid,
      {
        :replay_messages,
        [
          count: 1,
          filter: [display_recipient: "food", subject: "lunch"]
        ]
      }
    )
  end


  test "replay messages and count and resort" do
    {:ok, pid} = ReplayRedisClient.start_link(@redis_connection_string)
    assert :ok == GenServer.call(
      pid,
      {
        :replay_messages,
        [
          count: 1,
          resort: true
        ]
      }
    )
  end


  test "replay messages and resort with count and filter" do
    {:ok, pid} = ReplayRedisClient.start_link(@redis_connection_string)
    assert :ok == GenServer.call(
      pid,
      {
        :replay_messages,
        [
          count: 1,
          resort: true,
          filter: [display_recipient: "food", subject: "lunch"]
        ]
      }
    )
  end

end