#!/usr/bin/env bash
# ==============================================================================
# Sandbox Query Runner — Unified CLI Executor for SQL, MongoDB, Redis & GraphQL
# ==============================================================================
set -euo pipefail

MODE="${1:-status}"
QUERY="${2:-}"
VARIABLES="${3:-{}}"

case "$MODE" in
  status)
    echo "=== Docker Compose Sandbox Status ==="
    docker compose ps
    ;;

  sql)
    if [[ -z "$QUERY" ]]; then
      echo "Usage: $0 sql \"<SQL_QUERY>\"" >&2
      exit 1
    fi
    docker exec -i sql_interview_postgres psql -U admin -d interview_db -P pager=off -c "$QUERY"
    ;;

  sql-explain)
    if [[ -z "$QUERY" ]]; then
      echo "Usage: $0 sql-explain \"<SQL_QUERY>\"" >&2
      exit 1
    fi
    docker exec -i sql_interview_postgres psql -U admin -d interview_db -P pager=off -c "EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE, FORMAT TEXT) $QUERY"
    ;;

  mongo)
    if [[ -z "$QUERY" ]]; then
      echo "Usage: $0 mongo \"<MONGOSH_EXPRESSION>\"" >&2
      exit 1
    fi
    docker exec -i nosql_interview_mongo mongosh -u admin -p adminpassword --authenticationDatabase admin --quiet interview_nosql --eval "$QUERY"
    ;;

  redis)
    if [[ -z "$QUERY" ]]; then
      echo "Usage: $0 redis \"<REDIS_COMMAND>\"" >&2
      exit 1
    fi
    # shellcheck disable=SC2086
    docker exec -i cache_interview_redis redis-cli $QUERY
    ;;

  graphql)
    if [[ -z "$QUERY" ]]; then
      echo "Usage: $0 graphql '<GRAPHQL_QUERY>' '[JSON_VARIABLES]'" >&2
      exit 1
    fi
    PAYLOAD=$(python3 -c 'import json, sys; print(json.dumps({"query": sys.argv[1], "variables": json.loads(sys.argv[2])}))' "$QUERY" "$VARIABLES")
    curl -sS -X POST http://localhost:5000/graphql \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD" | python3 -m json.tool
    ;;

  *)
    echo "Unknown mode: '$MODE'. Supported modes: status | sql | sql-explain | mongo | redis | graphql" >&2
    exit 1
    ;;
esac

