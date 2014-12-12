defmodule ReplayClient do
    use Behaviour

    @doc "Shows recorded messages"
    defcallback replay_messages(Dict)

end
