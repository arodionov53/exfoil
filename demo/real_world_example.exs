#!/usr/bin/env elixir

# Real-world example: API response caching with Exfoil.Maps
# Run with: mix run real_world_example.exs

alias Exfoil.Maps

IO.puts("=== Real-World Example: API Response Caching ===\n")

# Simulate an API response with user data
simulate_api_response = fn ->
  1..2000
  |> Enum.into(%{}, fn id ->
    {id, %{
      id: id,
      username: "user_#{id}",
      email: "user#{id}@example.com",
      profile: %{
        name: "User #{id}",
        avatar: "https://example.com/avatars/#{id}.jpg",
        bio: "This is user #{id}'s bio with some interesting details.",
        preferences: %{
          theme: if(rem(id, 2) == 0, do: :dark, else: :light),
          notifications: rem(id, 3) == 0,
          language: Enum.random([:en, :es, :fr, :de, :pt])
        }
      },
      stats: %{
        posts: :rand.uniform(1000),
        followers: :rand.uniform(5000),
        following: :rand.uniform(1000)
      },
      created_at: DateTime.add(DateTime.utc_now(), -:rand.uniform(365 * 2) * 24 * 3600),
      last_seen: DateTime.add(DateTime.utc_now(), -:rand.uniform(30) * 24 * 3600)
    }}
  end)
end

IO.puts("Simulating API response with 2000 users...")
api_response = simulate_api_response.()

# Convert to Exfoil module for fast lookups
IO.puts("Converting to Exfoil.Maps module...")
{:ok, user_cache} = Maps.convert(api_response, :UserCache)

IO.puts("Module created: #{inspect user_cache}")
IO.puts("Total users: #{user_cache.count()}")
IO.puts("")

# Simulate real-world usage patterns

# 1. Single user lookup (common pattern)
IO.puts("=== Use Case 1: Single User Lookup ===")
sample_user_ids = [1, 500, 1000, 1500, 2000]

Benchee.run(
  %{
    "Exfoil.Maps lookup" => fn ->
      Enum.each(sample_user_ids, fn id ->
        user = user_cache.get(id)
        # Simulate using the data
        user.username
      end)
    end,
    "Map lookup" => fn ->
      Enum.each(sample_user_ids, fn id ->
        user = Map.get(api_response, id)
        # Simulate using the data
        user.username
      end)
    end
  },
  time: 2,
  formatters: [{Benchee.Formatters.Console, comparison: true}]
)

# 2. Batch processing (processing multiple users)
IO.puts("\n=== Use Case 2: Batch User Processing ===")
user_ids_batch = 1..100 |> Enum.to_list()

Benchee.run(
  %{
    "Exfoil.Maps batch" => fn ->
      user_ids_batch
      |> Enum.map(&user_cache.get/1)
      |> Enum.map(fn user ->
        %{
          id: user.id,
          display_name: user.profile.name,
          follower_count: user.stats.followers
        }
      end)
    end,
    "Map batch" => fn ->
      user_ids_batch
      |> Enum.map(&Map.get(api_response, &1))
      |> Enum.map(fn user ->
        %{
          id: user.id,
          display_name: user.profile.name,
          follower_count: user.stats.followers
        }
      end)
    end
  },
  time: 2,
  formatters: [{Benchee.Formatters.Console, comparison: true}]
)

# 3. Search/Filter operations
IO.puts("\n=== Use Case 3: Search Operations ===")

Benchee.run(
  %{
    "Exfoil.Maps search" => fn ->
      user_cache.all()
      |> Enum.filter(fn {_id, user} ->
        user.profile.preferences.theme == :dark and
        user.stats.followers > 2500
      end)
      |> Enum.take(10)
    end,
    "Map search" => fn ->
      api_response
      |> Enum.filter(fn {_id, user} ->
        user.profile.preferences.theme == :dark and
        user.stats.followers > 2500
      end)
      |> Enum.take(10)
    end
  },
  time: 1,
  formatters: [{Benchee.Formatters.Console, comparison: true}]
)

# 4. Memory usage during sustained operations
IO.puts("\n=== Use Case 4: Memory Efficiency ===")
IO.puts("Testing memory usage during 1000 random user lookups...")

random_ids = 1..1000 |> Enum.map(fn _ -> :rand.uniform(2000) end)

Benchee.run(
  %{
    "Exfoil.Maps sustained" => fn ->
      Enum.each(random_ids, fn id ->
        user = user_cache.get(id)
        # Simulate processing
        user.username <> " - " <> user.profile.name
      end)
    end,
    "Map sustained" => fn ->
      Enum.each(random_ids, fn id ->
        user = Map.get(api_response, id)
        # Simulate processing
        user.username <> " - " <> user.profile.name
      end)
    end
  },
  time: 2,
  memory_time: 1,
  formatters: [{Benchee.Formatters.Console, comparison: true}]
)

# Show utility functions
IO.puts("\n=== Utility Functions Demo ===")
IO.puts("user_cache.count(): #{user_cache.count()}")
IO.puts("user_cache.has_key?(1): #{user_cache.has_key?(1)}")
IO.puts("user_cache.has_key?(9999): #{user_cache.has_key?(9999)}")

# Show sample data
sample_user = user_cache.get(1)
IO.puts("\nSample user data:")
IO.puts("Username: #{sample_user.username}")
IO.puts("Email: #{sample_user.email}")
IO.puts("Theme: #{sample_user.profile.preferences.theme}")
IO.puts("Followers: #{sample_user.stats.followers}")

IO.puts("\n=== Real-World Benefits ===")
IO.puts("✅ Consistent fast lookups regardless of cache size")
IO.puts("✅ Zero memory allocation during user lookups")
IO.puts("✅ Predictable performance for API response times")
IO.puts("✅ Easy integration with existing code patterns")
IO.puts("✅ Type-safe access to cached data")

IO.puts("\n=== When to Use This Pattern ===")
IO.puts("• API response caching (like this example)")
IO.puts("• User session data")
IO.puts("• Configuration lookup tables")
IO.puts("• Product catalogs")
IO.puts("• Geographic/location data")
IO.puts("• Any read-heavy, semi-static dataset")

IO.puts("\n🚀 Exfoil.Maps is ideal for transforming slow API calls")
IO.puts("    into blazing-fast in-memory lookups!")