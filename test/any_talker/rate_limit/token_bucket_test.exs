defmodule AnyTalker.RateLimit.TokenBucketTest do
  use AnyTalker.DataCase, async: true

  alias AnyTalker.RateLimit.Bucket
  alias AnyTalker.RateLimit.Context
  alias AnyTalker.RateLimit.TokenBucket

  @context %Context{max_tokens: 10, refill_interval_ms: 60_000, refill_amount: 2}

  describe "allowed?/2" do
    test "returns true for new key" do
      assert TokenBucket.allowed?("new:1", @context)
    end

    test "returns true when tokens > 0" do
      {:ok, _remaining} = TokenBucket.increase("test:1", 5, @context)

      assert TokenBucket.allowed?("test:1", @context)
    end

    test "returns false when tokens = 0" do
      {:ok, _remaining} = TokenBucket.increase("test:2", 10, @context)

      refute TokenBucket.allowed?("test:2", @context)
    end

    test "returns false when tokens < 0" do
      {:ok, _remaining} = TokenBucket.increase("test:3", 15, @context)

      refute TokenBucket.allowed?("test:3", @context)
    end

    test "returns true after tokens refill" do
      {:ok, _remaining} = TokenBucket.increase("test:4", 10, @context)
      refute TokenBucket.allowed?("test:4", @context)

      # Simulate time passing by updating last_refill_at
      bucket = Repo.get!(Bucket, "test:4")
      past = DateTime.add(DateTime.utc_now(), -60, :second)

      bucket
      |> Ecto.Changeset.change(last_refill_at: past)
      |> Repo.update!()

      assert TokenBucket.allowed?("test:4", @context)
    end
  end

  describe "increase/3" do
    test "creates bucket with max_tokens on first call" do
      {:ok, remaining} = TokenBucket.increase("new:2", 3, @context)

      assert remaining == 7
    end

    test "subtracts tokens from existing bucket" do
      {:ok, 7} = TokenBucket.increase("test:5", 3, @context)
      {:ok, 4} = TokenBucket.increase("test:5", 3, @context)
      {:ok, 1} = TokenBucket.increase("test:5", 3, @context)

      assert Repo.get!(Bucket, "test:5").tokens == 1
    end

    test "allows tokens to go negative" do
      {:ok, remaining} = TokenBucket.increase("test:6", 15, @context)

      assert remaining == -5
      assert Repo.get!(Bucket, "test:6").tokens == -5
    end

    test "applies refill before subtracting" do
      {:ok, _remaining} = TokenBucket.increase("test:7", 10, @context)

      # Simulate time passing
      bucket = Repo.get!(Bucket, "test:7")
      past = DateTime.add(DateTime.utc_now(), -120, :second)

      bucket
      |> Ecto.Changeset.change(last_refill_at: past)
      |> Repo.update!()

      # 2 intervals passed, 2 tokens per interval = 4 tokens refilled
      # 0 + 4 = 4, then subtract 2 = 2
      {:ok, remaining} = TokenBucket.increase("test:7", 2, @context)

      assert remaining == 2
    end

    test "caps refill at max_tokens" do
      {:ok, _remaining} = TokenBucket.increase("test:8", 2, @context)

      # Simulate long time passing
      bucket = Repo.get!(Bucket, "test:8")
      past = DateTime.add(DateTime.utc_now(), -3600, :second)

      bucket
      |> Ecto.Changeset.change(last_refill_at: past)
      |> Repo.update!()

      # Should cap at max_tokens (10), then subtract 1
      {:ok, remaining} = TokenBucket.increase("test:8", 1, @context)

      assert remaining == 9
    end

    test "updates last_refill_at on each call" do
      {:ok, _remaining} = TokenBucket.increase("test:9", 1, @context)
      bucket1 = Repo.get!(Bucket, "test:9")

      Process.sleep(10)

      {:ok, _remaining} = TokenBucket.increase("test:9", 1, @context)
      bucket2 = Repo.get!(Bucket, "test:9")

      assert DateTime.after?(bucket2.last_refill_at, bucket1.last_refill_at)
    end
  end

  describe "time_until_allowed/2" do
    test "returns nil for new key" do
      assert TokenBucket.time_until_allowed("time:new", @context) == nil
    end

    test "returns 0 when tokens > 0" do
      {:ok, _remaining} = TokenBucket.increase("time:1", 5, @context)

      assert TokenBucket.time_until_allowed("time:1", @context) == 0
    end

    test "returns time for single refill when tokens = 0" do
      {:ok, _remaining} = TokenBucket.increase("time:2", 10, @context)

      # tokens = 0, need 1 token, refill_amount = 2
      # Should need 1 refill interval (60_000ms)
      time = TokenBucket.time_until_allowed("time:2", @context)

      assert time > 0
      assert time <= 60_000
    end

    test "returns correct time for deep negative balance" do
      # max_tokens = 10, refill_amount = 2, refill_interval = 60_000ms
      # Use 13 tokens: 10 - 13 = -3
      {:ok, -3} = TokenBucket.increase("time:3", 13, @context)

      # Need to get from -3 to 1, so need 4 tokens
      # With refill_amount = 2, need 2 refill intervals
      time = TokenBucket.time_until_allowed("time:3", @context)

      # Should be approximately 2 intervals (120_000ms)
      assert time > 60_000
      assert time <= 120_000
    end

    test "accounts for elapsed time since last refill" do
      {:ok, _remaining} = TokenBucket.increase("time:4", 10, @context)

      # Simulate 30 seconds passing (half an interval)
      bucket = Repo.get!(Bucket, "time:4")
      past = DateTime.add(DateTime.utc_now(), -30, :second)

      bucket
      |> Ecto.Changeset.change(last_refill_at: past)
      |> Repo.update!()

      time = TokenBucket.time_until_allowed("time:4", @context)

      # Should be approximately 30 seconds until next refill
      assert time > 0
      assert time <= 30_000
    end

    test "returns 0 after sufficient time has passed" do
      {:ok, _remaining} = TokenBucket.increase("time:5", 10, @context)

      # Simulate 60 seconds passing (1 full interval)
      bucket = Repo.get!(Bucket, "time:5")
      past = DateTime.add(DateTime.utc_now(), -60, :second)

      bucket
      |> Ecto.Changeset.change(last_refill_at: past)
      |> Repo.update!()

      # After 1 interval: 0 + 2 = 2 tokens, which is > 0
      assert TokenBucket.time_until_allowed("time:5", @context) == 0
    end
  end
end
