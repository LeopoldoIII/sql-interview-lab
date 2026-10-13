# 🔴 Complete Redis Guide: Caching, Data Structures & Patterns

This guide accompanies the **Redis 7** container (`cache_interview_redis`) and the **RedisInsight** GUI (`cache_interview_redisinsight`).

---

## ⚡ Connection and Tools

* **Web GUI (RedisInsight):** 👉 **[http://localhost:5540](http://localhost:5540)**
* **Interactive Redis CLI:**
  ```bash
  docker exec -it cache_interview_redis redis-cli
  ```
* **Seed initial dataset:**
  ```bash
  docker exec -i cache_interview_redis redis-cli < redis_init/01_init.redis
  ```

---

## 🧭 Why is Redis Asked in Technical Interviews?

Unlike disk-based databases (such as PostgreSQL), Redis stores everything in memory (RAM). It is an **In-Memory Data Structure Store**, providing sub-millisecond ($< 1\text{ms}$) latency.

Interviews typically evaluate:
1. Selecting the right data structure for specific problem scenarios.
2. Expiration management (`TTL`) and caching strategies (*Cache-Aside pattern*).
3. Task processing queues (Lists) and real-time ranking (*Sorted Sets*).

---

## 📌 Guide by Data Type

### 1. Strings (Key-Value, Atomic Counters & TTL)
Best for: Session tokens, atomic counters, and cached API payloads.

```redis
# Store a session token expiring in 60 seconds
SETEX user:101:token 60 "session_token_xyz"

# Retrieve value
GET user:101:token

# Check remaining Time-To-Live in seconds
TTL user:101:token

# Increment an atomic counter (e.g. page visits)
INCR page:home:views
INCRBY page:home:views 10
```

---

### 2. Hashes (Objects & Dictionaries)
Best for: Representing domain entities with individual fields (saves memory compared to serializing large JSON strings).

```redis
# Set fields for an employee
HSET employee:101 name "Alice Smith" department "Engineering" salary "85000"

# Retrieve all fields and values
HGETALL employee:101

# Retrieve a single field
HGET employee:101 salary

# Increment a numeric field (e.g. salary raise)
HINCRBY employee:101 salary 5000
```

---

### 3. Lists (FIFO Queues & LIFO Stacks)
Best for: Asynchronous task queues, recent event streams.

```redis
# Enqueue tasks to the tail (RPUSH)
RPUSH email_queue "send_welcome_user_101"
RPUSH email_queue "send_invoice_user_102"

# Queue length
LLEN email_queue

# Inspect items without popping
LRANGE email_queue 0 -1

# Dequeue from the head for worker processing (LPOP FIFO)
LPOP email_queue
```

---

### 4. Sets (Unordered Unique Collections)
Best for: Tags, skills, mutual relationships, deduplication.

```redis
# Add skills to a set
SADD user:101:skills "JavaScript" "Python" "MongoDB"
SADD user:102:skills "Python" "PostgreSQL" "Docker"

# Retrieve all elements
SMEMBERS user:101:skills

# Set intersection: Which skills do user 101 and 102 have in common?
SINTER user:101:skills user:102:skills
# Result: ["Python"]

# Check if an element belongs to the set (O(1))
SISMEMBER user:101:skills "Python"
```

---

### 5. Sorted Sets / ZSET (Ranked Sets with Scores)
Best for: **Real-time Leaderboards**, priority queues, and sliding-window rate limiters.

Every member is associated with a floating-point `Score` that Redis uses to keep elements sorted automatically.

```redis
# Add employee sales scores (ZADD key score member)
ZADD sales_leaderboard 12400 "employee:6"
ZADD sales_leaderboard 3900  "employee:7"
ZADD sales_leaderboard 5000  "employee:3"

# Top 3 salespeople from highest to lowest with scores (ZREVRANGE)
ZREVRANGE sales_leaderboard 0 2 WITHSCORES

# Increment a member's score after a new sale
ZINCRBY sales_leaderboard 1500 "employee:7"

# Get rank position of an employee (0-indexed)
ZREVRANK sales_leaderboard "employee:6"
```

---

### 6. Deduplication Patterns & Uniqueness in Redis

Unlike relational databases where you scan tables with `GROUP BY` to find duplicates that already entered the system, **Redis is primarily used as an active deduplication engine to prevent duplicate processing in real time**:

```
+--------------------------------------------------------------------------------------------------+
|                                  REDIS DEDUPLICATION STRATEGIES                                  |
+------------------------------+---------------------------+---------------------------------------+
| Use Case                     | Redis Command / Type      | Memory & Performance Profile          |
+------------------------------+---------------------------+---------------------------------------+
| Webhook & Payment Idempotency| SET key val NX EX <ttl>   | O(1) lock, auto-cleans via TTL        |
| Task Queue Deduplication     | SADD seen_items <id>      | O(1) membership check before RPUSH    |
| Big Data Unique Counting     | HyperLogLog (PFADD/COUNT) | Fixed 12 KB memory for millions of IDs|
+------------------------------+---------------------------+---------------------------------------+
```

---

#### 6.1 The Distributed Idempotency Lock Pattern (`SET ... NX EX`)
* **Scenario:** A client double-clicks "Submit Order" or a payment provider (Stripe, PayPal) sends the same webhook twice.
* **Mechanism:** Use atomic `SET` with:
  * **`NX`**: Only set the key if it does **N**ot e**X**ist.
  * **`EX <seconds>`**: Expire automatically after the deduplication window expires.

```redis
# 1st Attempt (Original request):
SET idempotency:checkout:order_8921 "in_progress" NX EX 120
# Output: OK (Acquired lock, process the order)

# 2nd Attempt (Duplicate retry within 120 seconds):
SET idempotency:checkout:order_8921 "in_progress" NX EX 120
# Output: (nil) -> Reject immediately as duplicate!
```

---

#### 6.2 Event & Message Queue Deduplication (`SADD` guard)
* **Problem:** Redis `Lists` (`RPUSH`) allow duplicate items. If producers retry, consumers process the same job multiple times.
* **Solution:** Guard the queue with a Redis `Set`:

```redis
# Check and track event ID in a Set:
SADD processed_events "evt_998124"
# Returns 1 -> Brand new event, proceed to: RPUSH task_queue "evt_998124"

# If the same event arrives again:
SADD processed_events "evt_998124"
# Returns 0 -> Duplicate detected! Skip enqueueing.
```

---

#### 6.3 Massive Scale Unique Counting (`HyperLogLog`: `PFADD` & `PFCOUNT`)
* **Problem:** Counting distinct daily active users (DAU) or unique page visitors where you only need the **cardinality count**, not the full list of IDs.
* **Comparison:**
  * Storing 100,000,000 unique IDs in a `Set`: Requires **~800 MB to 1.5 GB** of RAM.
  * `HyperLogLog`: Uses a constant **12 KB of memory** regardless of how many millions of items you add (standard error < 0.81%).

```redis
# Add user IDs to a daily unique visitor log:
PFADD unique_visitors:2026-10-13 "user:101" "user:102" "user:103"
PFADD unique_visitors:2026-10-13 "user:101" # Duplicate user: will not increment count!

# Retrieve the deduplicated unique count:
PFCOUNT unique_visitors:2026-10-13
# Returns: 3 (correctly ignores the duplicate user:101)
```

---

## 🎯 Redis Practice Challenges

#### Challenge 1: Simple Rate Limiting / Lock
> **Problem:** A user attempts to log in. How do you set a lock that blocks subsequent attempts for 30 seconds only if no lock currently exists?

<details>
<summary>🔍 View Solution</summary>

```redis
# SET with NX (only if Not eXists) and EX (expire in seconds)
SET login_lock:user:101 "locked" EX 30 NX
```
If the key already exists, Redis returns `nil` and the application rejects the request.
</details>

#### Challenge 2: Top Sales Leader
> **Problem:** Query `sales_leaderboard` to return only the single #1 top salesperson with their score.

<details>
<summary>🔍 View Solution</summary>

```redis
ZREVRANGE sales_leaderboard 0 0 WITHSCORES
```
</details>

#### Challenge 3: Deduplicated Unique Event Counter
> **Problem:** Log five user interactions (`"usr_1"`, `"usr_2"`, `"usr_1"`, `"usr_3"`, `"usr_2"`) into a structure named `hll:daily_users` and return the total deduplicated user count.

<details>
<summary>🔍 View Solution</summary>

```redis
PFADD hll:daily_users "usr_1" "usr_2" "usr_1" "usr_3" "usr_2"
PFCOUNT hll:daily_users
# Returns: 3
```
</details>

