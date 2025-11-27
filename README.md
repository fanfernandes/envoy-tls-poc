# Envoy TLS Origination POC (Using AI)

## ✅ Proof of Concept: COMPLETE

**Two POC variants available**:
1. **Simple POC** - Proves TLS origination with single destination (httpbin.org)
2. **Dynamic POC** - Production-like with multiple destinations (any HTTPS endpoint)

Both prove: HTTPoison → Plain HTTP → Envoy → TLS origination → HTTPS upstream

---

# Envoy TLS Origination POC

This POC demonstrates that Envoy can handle TLS origination for HTTPoison/Elixir clients, supporting the architectural approach for DEVECO-218.

## 🎯 What We Proved

**Both POCs prove**:
1. ✅ **HTTPoison sends plain HTTP** (no `:ssl` options) to Envoy
2. ✅ **Envoy originates TLS** to HTTPS upstream with certificate validation
3. ✅ **No Erlang SSL involvement** - TLS is transparent to the application
4. ✅ **Code changes are minimal** - Just URL conversion (HTTPS → HTTP)

**Dynamic POC additionally proves**:
5. ✅ **Routes to multiple destinations** based on Host header (httpbin.org, api.github.com, jsonplaceholder.com)
6. ✅ **Production-like behavior** - mirrors how Istio Envoy sidecar works

## Architecture Flow

### Simple POC (Single Destination)
```
┌─────────────────────┐      Plain HTTP      ┌──────────────────┐
│  Elixir/HTTPoison   │─────────────────────>│   Envoy Proxy    │
│  (test.exs)         │   localhost:10000     │  (Hardcoded)     │
│                     │                       │                  │
│  NO :ssl options    │                       │  - TLS origin    │
└─────────────────────┘                       │  - Validate CA   │
                                               └──────────────────┘
                                                       │
                                                       │ HTTPS/TLS 1.2+
                                                       ▼
                                              ┌──────────────────┐
                                              │  httpbin.org:443 │
                                              └──────────────────┘
```

### Dynamic POC (Multiple Destinations)
```
┌─────────────────────┐      Plain HTTP       ┌──────────────────┐
│  Elixir/HTTPoison   │─────────────────────> │   Envoy Proxy    │
│  (test-dynamic.exs) │   localhost:10000     │  (Dynamic)       │
│                     │   + Host header       │                  │
│  NO :ssl options    │                       │  - Route by Host │
└─────────────────────┘                       │  - TLS origin    │
                                              │  - Validate CA   │
                                              └──────────────────┘
                                                       │
                     ┌─────────────────────────────────┼─────────────────────┐
                     │                                 │                     │
                     │ HTTPS/TLS 1.2+                  │                     │
                     ▼                                 ▼                     ▼
            ┌──────────────────┐           ┌──────────────────┐   ┌─────────────────┐
            │  httpbin.org:443 │           │ api.github.com   │   │ customer.com    │
            └──────────────────┘           └──────────────────┘   └─────────────────┘
```

## 📁 Files

```
envoy-poc/
├── envoy.yaml                    # Simple: Hardcoded to httpbin.org
├── envoy-dynamic.yaml            # Dynamic: Routes to any destination
├── run-envoy.sh                  # Docker Start simple Envoy (single destination)
├── run-envoy-dynamic.sh          # Docker Start dynamic Envoy (multiple destinations)
├── test.exs                      # Simple POC test
├── test-dynamic.exs              # Dynamic routing test (production-like)
├── README.md                     # This file - Quick start & results
```

## 🚀 Quick Start

### Option 1: Simple POC (Single Destination)

**Best for**: Proving TLS origination concept

```bash
# Start Envoy (routes to httpbin.org only)
./run-envoy.sh

# Test with curl
curl http://localhost:10000/get

# Test with Elixir
elixir test.exs

# Check TLS metrics
curl http://localhost:9901/stats | grep ssl
```

### Option 2: Dynamic Routing POC (Multiple Destinations) 🌟

**Best for**: Production-like behavior with multiple webhook destinations

```bash
# Start Envoy with dynamic routing
./run-envoy-dynamic.sh

# Test multiple destinations
elixir test-dynamic.exs

# Manual tests to different destinations
curl -H "Host: httpbin.org" http://localhost:10000/get
curl -H "Host: api.github.com" http://localhost:10000/zen
curl -H "Host: jsonplaceholder.typicode.com" http://localhost:10000/todos/1

# Check TLS metrics (shows multiple handshakes)
curl http://localhost:9901/stats | grep "ssl.handshake"
```

**Recommendation**: Start with Simple POC to prove concept, then try Dynamic POC to see production-like routing!

---

## 📊 Results

### ✅ Simple POC Results

**curl test:**
```
HTTP/1.1 200 OK
server: envoy
x-envoy-upstream-service-time: 1364
```

**Envoy SSL Metrics:**
```
cluster.https_upstream.ssl.handshake: 1
cluster.https_upstream.ssl.connection_error: 0
cluster.https_upstream.ssl.fail_verify_error: 0
cluster.https_upstream.ssl.versions.TLSv1.2: 1
```

**Elixir HTTPoison test:**
```elixir
# Plain HTTP request - NO :ssl options needed!
HTTPoison.get("http://localhost:10000/get", [], timeout: 10_000)

# Result: ✅ 200 OK
# - Origin IP: 85.245.36.240
# - URL seen by httpbin: https://localhost/get
# - Server: envoy
```

---

### ✅ Dynamic POC Results

**Multiple destination test:**
```
📝 Test 1: httpbin.org
✅ SUCCESS: Status 200 OK
  - URL seen by upstream: https://httpbin.org/get

📝 Test 2: GitHub API  
✅ SUCCESS: Status 200 OK
  - Response from api.github.com

📝 Test 3: JSONPlaceholder
✅ SUCCESS: Status 200 OK
  - Response from jsonplaceholder.typicode.com
```

**Envoy SSL Metrics (Dynamic):**
```
cluster.dynamic_forward_proxy_cluster.ssl.handshake: 3        # 3 destinations!
cluster.dynamic_forward_proxy_cluster.ssl.connection_error: 0
cluster.dynamic_forward_proxy_cluster.ssl.fail_verify_error: 0
```

**Key proof**: Same Envoy instance handled TLS to 3 different HTTPS destinations! ✅

---

## 🎓 What It Can Solve

### Problem: IR-474 (Erlang SSL Issues)
- ❌ Outdated CA certificates in WDS
- ❌ Fragile to Erlang version upgrades
- ❌ Hard to test and maintain

### Solution: Move TLS to Envoy
- ✅ Centralized certificate management (Istio ConfigMap)
- ✅ No Erlang SSL dependency
- ✅ Better observability (Envoy metrics)
- ✅ Easier to update certificates (no WDS redeployment)

---


## 🛑 Cleanup

### Simple POC
```bash
# Stop Envoy
docker stop envoy-poc

# Remove container
docker rm envoy-poc
```

### Dynamic POC
```bash
# Same cleanup (uses same container name)
docker stop envoy-poc
docker rm envoy-poc
```

**Note**: Both POCs use the same container name (`envoy-poc`), so starting one stops the other automatically.

---

## 🎓 What Each POC Proves

### Simple POC (envoy.yaml)
✅ HTTPoison can send plain HTTP (no `:ssl` options)  
✅ Envoy handles TLS origination  
✅ Certificate validation works  
✅ No Erlang SSL/TLS needed  
✅ Solves IR-474 (Erlang SSL issues)

### Dynamic POC (envoy-dynamic.yaml)
✅ All of the above, PLUS:  
✅ Routes to multiple HTTPS destinations  
✅ Host header-based routing (like production!)  
✅ Works with any customer webhook URL  
✅ Matches production Istio behavior

---

## 📚 References

- [Envoy TLS Configuration](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/ssl)
- [Istio Egress TLS Origination](https://istio.io/latest/docs/tasks/traffic-management/egress/egress-tls-origination/)
- [HTTPoison Documentation](https://hexdocs.pm/httpoison/)

---

**POC Status**: ✅ **COMPLETE** - Ready for DEVECO-218 implementation planning
