defmodule ReplayFileClientTest do
  use ExUnit.Case


  setup do
    Application.delete_env(:zulex, :redis_connection_string)
    case StateManager.start_link(%ZulipAPICredentials{:key => "key", :email => "email"}) do
      {:ok, pid} -> on_exit fn -> Process.exit(pid, :shutdown) end
      _          -> on_exit fn -> end
    end
  end


  test "start" do
    {:ok, pid} = ReplayFileClient.start_link
    assert Process.alive?(pid)
  end

end
