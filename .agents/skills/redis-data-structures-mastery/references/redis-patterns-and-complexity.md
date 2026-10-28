# Redis 7 Patterns & Big-O Complexity Reference

## 1. Command Time-Complexity Cheatsheet

| Data Structure | Command | Time Complexity | Interview & Production Notes |
| :--- | :--- | :--- | :--- |
| **String** | `GET` / `SET` / `INCR` / `INCRBY` | $O(1)$ | Ideal for counters, sessions, and distributed locks. |
| **Hash** | `HSET` / `HGET` / `HINCRBY` | $O(1)$ per field | Prefer over JSON Strings when updating individual fields frequently. |
| **Hash** | `HGETALL` | $O(N)$ | Safe for small entity profiles ($N < 100$ fields); use `HSCAN` or `HMGET` for large hashes. |
| **List** | `LPUSH` / `RPOP` / `BLPOP` | $O(1)$ | Native FIFO/LIFO queue. |
| **List** | `LRANGE start stop` | $O(S + N)$ | Keep bounded with `LTRIM key 0 99` for recent activity feeds. |
| **Set** | `SADD` / `SREM` / `SISMEMBER` | $O(1)$ | Instant membership check (unlike $O(N)$ list scan). |
| **Set** | `SINTER` / `SUNION` / `SDIFF` | $O(N \cdot M)$ | Intersects smallest set first; run on replica or cache result if sets are huge. |
| **Sorted Set** | `ZADD` / `ZINCRBY` / `ZREVRANK` | $O(\log N)$ | Backed by Skip List + Hash Table. |
| **Sorted Set** | `ZREVRANGE start stop WITHSCORES` | $O(\log N + M)$ | $M$ is the number of elements returned. Ideal for top-K leaderboards. |
| **HyperLogLog** | `PFADD` / `PFCOUNT` | $O(1)$ | Probabilistic cardinality with $0.81\%$ standard error using at most 12 KB. |
| **Keyspace** | `SCAN cursor MATCH pattern COUNT k` | $O(1)$ per call, $O(N)$ full | Always use instead of blocking `KEYS *`. |

---

## 2. Production Interview Patterns

### A. Atomic Idempotency Key / Distributed Lock
```redis
# Acquire lock/idempotency key only if it does not exist (NX) with a 60-second TTL (EX 60)
SET idempotency:payment:tx_9001 "in_progress" NX EX 60
```

### B. Sliding-Window Rate Limiter (Sorted Set Pattern)
To limit `user:101` to $K$ requests per 60-second rolling window (using Unix timestamp in ms as score):
```redis
# 1. Remove timestamps older than (now - 60000ms)
ZREMRANGEBYSCORE ratelimit:user:101 -inf 1700000000000
# 2. Add current request timestamp
ZADD ratelimit:user:101 1700000060000 "req:1700000060000:uuid1"
# 3. Count active requests in current window
ZCARD ratelimit:user:101
# 4. Reset TTL on the key so inactive users self-expire
EXPIRE ratelimit:user:101 60
```

### C. Safe Cursor Iteration (`SCAN`)
```redis
# Never run KEYS user:* in production; iterate safely with SCAN:
SCAN 0 MATCH user:*:session COUNT 100
```

