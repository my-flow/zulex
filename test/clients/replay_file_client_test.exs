defmodule ReplayFileClientTest do
  use ExUnit.Case

  test "start" do
    {:ok, pid} = ReplayFileClient.start_link
    assert Process.alive?(pid)
  end


  test "replay messages with count 0" do
    {:ok, pid} = ReplayFileClient.start_link
    assert :ok == GenServer.call(pid, {:replay_messages, [count: 0]})
  end


  test "replay messages with count 1" do
    {:ok, pid} = ReplayFileClient.start_link
    assert :ok == GenServer.call(pid, {:replay_messages, [count: 1]})
  end


  test "replay messages and count with filter" do
    {:ok, pid} = ReplayFileClient.start_link
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
    {:ok, pid} = ReplayFileClient.start_link
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
    {:ok, pid} = ReplayFileClient.start_link
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
