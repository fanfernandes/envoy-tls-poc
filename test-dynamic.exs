#!/usr/bin/env elixir

# Production-Like POC - Dynamic Routing
# This demonstrates how Envoy routes to different destinations based on Host header

Mix.install([
  {:httpoison, "~> 2.2"},
  {:jason, "~> 1.4"}
])

IO.puts("\n🔬 Production-Like POC - Dynamic Routing\n")
IO.puts(String.duplicate("=", 60))

# Function to test a URL
defmodule EnvoyTest do
  def test_url(original_url, description) do
    IO.puts("\n📝 #{description}")
    IO.puts(String.duplicate("-", 60))

    # Convert HTTPS → HTTP (like production WDS would)
    envoy_url = String.replace(original_url, ~r/^https:\/\//, "http://")

    # Extract host for the Host header
    host = URI.parse(original_url).host

    IO.puts("Original URL: #{original_url}")
    IO.puts("Converted URL: #{envoy_url}")
    IO.puts("Host header: #{host}")

    # In production, iptables redirects to Envoy automatically
    # In local POC, we manually send to localhost:10000 but preserve Host header
    local_url = "http://localhost:10000" <> URI.parse(envoy_url).path
    headers = [{"Host", host}]  # This tells Envoy where to route!

    IO.puts("Actual request: #{local_url}")
    IO.puts("With header: Host: #{host}\n")

    case HTTPoison.get(local_url, headers, timeout: 10_000, recv_timeout: 10_000) do
      {:ok, response} ->
        if response.status_code == 200 do
          IO.puts("✅ SUCCESS: Status 200 OK")

          # Find the "url" in response to see what the upstream saw
          case Jason.decode(response.body) do
            {:ok, json} ->
              IO.puts("  - URL seen by upstream: #{json["url"]}")
              IO.puts("  - Origin IP: #{json["origin"]}")
            _ ->
              IO.puts("  - Response received successfully")
          end
        else
          IO.puts("⚠️  Status code: #{response.status_code}")
        end

      {:error, error} ->
        IO.puts("❌ ERROR: #{inspect(error.reason)}")
    end
  end
end

# Test different destinations
EnvoyTest.test_url(
  "https://httpbin.org/get",
  "Test 1: httpbin.org"
)

EnvoyTest.test_url(
  "https://api.github.com/zen",
  "Test 2: GitHub API"
)

EnvoyTest.test_url(
  "https://jsonplaceholder.typicode.com/todos/1",
  "Test 3: JSONPlaceholder"
)

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("\n✨ Production-Like POC Complete!")
IO.puts("\n🎯 Key Takeaway:")
IO.puts("  Different Host headers route to different HTTPS destinations")
IO.puts("  Just like production WDS with Istio Envoy sidecar!")
IO.puts("  iptables would do this redirect automatically in Kubernetes\n")
