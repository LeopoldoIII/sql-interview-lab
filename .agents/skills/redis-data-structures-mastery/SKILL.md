---
name: redis-data-structures-mastery
description: >-
  Use this skill whenever designing, reviewing, or optimizing Redis 7 commands,
  keyspace schemas, caching strategies, rate limiters, distributed locks, or
  real-time leaderboards in this project.
---

# Redis 7 Data Structures & Caching Mastery

Follow this workflow whenever authoring or reviewing Redis commands in [`redis_practice.redis`](../../redis_practice.redis), [`redis_init/01_init.redis`](../../redis_init/01_init.redis), or [`docs/REDIS_GUIDE.md`](../../docs/REDIS_GUIDE.md).

> **Language Rule:** All Redis key names, commands, scripts, comments, and explanations MUST be written in **English**.

---

## 1. Step-by-Step Redis Engineering Workflow

1. **Design the Keyspace Schema:**
   - Follow `<domain>:<entity_id>:<attribute>` convention (e.g., `employee:101`, `user:101:session`, `user:101:skills`, `leaderboard:sales`).
2. **Select the Optimal Data Structure by Access Pattern & Time Complexity:**
   - Need atomic counter, session token, or lock? $\rightarrow$ **String** (`SET ... EX`, `INCR`, `SET ... NX EX`).
   - Need structured entity attributes with partial field updates? $\rightarrow$ **Hash** (`HSET`, `HGET`, `HMGET`, `HINCRBY`).
   - Need a simple FIFO/LIFO work queue or bounded recent-items list? $\rightarrow$ **List** (`LPUSH`, `RPOP`, `BLPOP`, `LTRIM`).
   - Need unique tags/skills and fast set intersections? $\rightarrow$ **Set** (`SADD`, `SISMEMBER`, `SINTER`).
   - Need ranked leaderboards or sliding-window rate limiting? $\rightarrow$ **Sorted Set (`ZSET`)** (`ZADD`, `ZINCRBY`, `ZREVRANGE`, `ZREVRANK`).
   - Need massive unique cardinality counting with minimal RAM? $\rightarrow$ **HyperLogLog** (`PFADD`, `PFCOUNT`).
3. **Enforce TTL & Non-Blocking Operations:**
   - Always attach TTLs (`EX` / `PX`) to ephemeral keys.
   - Never use `KEYS *`; always use `SCAN 0 MATCH <pattern> COUNT 100`.
   - Use `UNLINK` instead of `DEL` when evicting large collection keys.
4. **Verify Against `cache_interview_redis`:**
   - Execute commands via [`sandbox-query-runner`](../sandbox-query-runner/SKILL.md):
     ```bash
     bash .agents/skills/sandbox-query-runner/scripts/run_query.sh redis "ZREVRANGE sales_leaderboard 0 -1 WITHSCORES"
     ```

---

## 2. Deep Reference Manual

For the complete Redis Big-O complexity cheatsheet and production patterns (Cache-Aside, Sliding-Window Rate Limiter, Distributed Locks), read:
- [Redis Patterns & Complexity Reference](./references/redis-patterns-and-complexity.md)

