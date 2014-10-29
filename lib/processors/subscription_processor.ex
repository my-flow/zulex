defmodule SubscriptionProcessor do
    use Processor.Base

    def process_url(_) do
        base_url <> "users/me/subscriptions"
    end
end
