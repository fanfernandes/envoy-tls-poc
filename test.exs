#!/usr/bin/env elixir

# Envoy TLS Origination POC - Elixir Test
# This demonstrates HTTPoison sending plain HTTP to Envoy,
# which handles TLS origination to HTTPS upstream

Mix.install([
  {:httpoison, "~> 2.2"},
  {:jason, "~> 1.4"}
])

IO.puts("\n🔬 Envoy TLS Origination POC - Elixir Test\n")
IO.puts(String.duplicate("=", 60))

# Test 1: Plain HTTP request to Envoy (which does HTTPS to httpbin.org)
IO.puts("\n📝 Test 1: HTTPoison → Envoy (plain HTTP) → httpbin.org (HTTPS)")
IO.puts(String.duplicate("-", 60))

# Simulate production: Start with HTTPS URL, convert to HTTP for Envoy
https_url = "https://localhost:10000/get"
IO.puts("Original URL: #{https_url}")

# Convert HTTPS → HTTP so Envoy handles TLS, not Erlang
url = String.replace(https_url, ~r/^https:\/\//, "http://")
IO.puts("Converted URL: #{url}")
IO.puts("Note: No :ssl options - TLS handled by Envoy!\n")

case HTTPoison.get(url, [], timeout: 10_000, recv_timeout: 10_000) do
  {:ok, response} ->
    if response.status_code == 200 do
      IO.puts("✅ SUCCESS: Status 200 OK")
      IO.puts("\nResponse Headers:")

      response.headers
      |> Enum.filter(fn {k, _v} -> String.downcase(k) in ["server", "date", "content-type", "x-envoy-upstream-service-time"] end)
      |> Enum.each(fn {key, value} -> IO.puts("  #{key}: #{value}") end)

      body_preview = response.body |> String.slice(0..200)
      IO.puts("\nResponse Body (first 200 chars):")
      IO.puts("  #{body_preview}...")

      # Parse JSON to show it's real data
      case Jason.decode(response.body) do
        {:ok, json} ->
          IO.puts("\n📊 Parsed Response Data:")
          IO.puts("  - Origin IP: #{json["origin"]}")
          IO.puts("  - URL seen by httpbin: #{json["url"]}")
          IO.puts("  - Headers received: #{map_size(json["headers"])} headers")
        _ -> :ok
      end
    else
      IO.puts("⚠️  Unexpected status code: #{response.status_code}")
    end

  {:error, error} ->
    IO.puts("❌ ERROR: #{inspect(error.reason)}")
    IO.puts("\nMake sure Envoy is running:")
    IO.puts("  ./run-envoy.sh")
end

# Test 2: POST request with body
IO.puts("\n\n📝 Test 2: POST request with JSON body")
IO.puts(String.duplicate("-", 60))

# Simulate production: Start with HTTPS URL, convert to HTTP for Envoy
https_post_url = "https://localhost:10000/post"
post_url = String.replace(https_post_url, ~r/^https:\/\//, "http://")

post_body = Jason.encode!(%{message: "Hello from Elixir!", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()})
post_headers = [{"Content-Type", "application/json"}]

IO.puts("Original URL: #{https_post_url}")
IO.puts("Converted URL: #{post_url}")
IO.puts("Body: #{post_body}")

case HTTPoison.post(post_url, post_body, post_headers, timeout: 10_000, recv_timeout: 10_000) do
  {:ok, response} ->
    if response.status_code == 200 do
      IO.puts("✅ SUCCESS: POST request completed")

      case Jason.decode(response.body) do
        {:ok, json} ->
          IO.puts("\n📊 Server echoed back:")
          IO.puts("  - Data: #{json["data"]}")
        _ -> :ok
      end
    else
      IO.puts("⚠️  Unexpected status code: #{response.status_code}")
    end

  {:error, error} ->
    IO.puts("❌ ERROR: #{inspect(error.reason)}")
end

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("\n✨ POC Complete!")
IO.puts("\n🎯 Key Takeaway:")
IO.puts("  HTTPoison sent plain HTTP (no :ssl options)")
IO.puts("  Envoy handled TLS origination to HTTPS upstream")
IO.puts("  Certificate validation enforced by Envoy, not Erlang!\n")
