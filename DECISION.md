# Decision: proxy tool — 2026-11-22 (owner: Seif)

**Chosen: OpenResty (NGINX + Lua).** Fallback: mitmproxy (only if OpenResty blocks us for >1 day).

## Why
- Lua checks Redis inside the request (`access_by_lua_block`), so one hop decides REAL vs DECOY.
- `lua-resty-redis` ships in the official image, nothing extra to install.
- Production-grade, low latency; normal users are not slowed down (100 ms Redis timeout).
- mitmproxy is Python and easy to script but slower and less "real" for the paper's architecture section.

## Contracts other people depend on
| Contract | Value | Who uses it |
|---|---|---|
| Flag key | `flag:<client-ip>`, set with `SET flag:<ip> <unix-ts> EX 600` | Omar (detector writes), el-Tanikhy (Redis) |
| Flag meaning | key exists => all requests from that IP go to decoy until TTL ends | everyone |
| Redis down | **fail-open**: everyone goes to real Grafana | gate "normal user unaffected" |
| Access log | JSON on stdout: ts, ip, method, uri, status, route, rt, ua | Omar (dummy detector counts req/min) |
| Backends | Services `grafana:3000` (real), `grafana-decoy:3000` (decoy) | Sohaib, Tarek |
| Proxy port | container 8080, Service `proxy:80`, health `/healthz` | Sohaib (attacker/Locust target) |

## Risk to fix this week: client IP in k3d
Traffic coming from the laptop through the k3d load balancer gets SNAT'ed, so attacker and normal user
look like the same IP and the normal user gets diverted too. For the gate: **run the attacker script and Locust
as pods inside the cluster** hitting `http://proxy.net/` (each pod keeps its own IP).

## Status
- Local loop tested with docker compose (`local-test/test.sh`): flag -> attacker DECOY, user REAL; TTL expiry -> back to REAL; Redis down -> fail-open. PASS.
- k3d manifest (`k8s/proxy.yaml`) written, **not yet run on k3d**; namespaces are placeholders.
