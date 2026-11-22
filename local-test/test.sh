#!/usr/bin/env bash
# Runs the full check: both REAL -> flag attacker -> attacker DECOY, user REAL -> TTL expiry -> REAL.
set -euo pipefail
cd "$(dirname "$0")"
dc() { docker compose "$@"; }
hit() { dc exec -T "$1" curl -s http://proxy:8080/; }
dc up -d --quiet-pull >/dev/null; sleep 3
ATTACKER_IP=$(dc exec -T attacker hostname -i | tr -d '[:space:]')
echo "1) before flag   attacker=$(hit attacker)  user=$(hit user)"
dc exec -T redis redis-cli SET "flag:$ATTACKER_IP" "$(date +%s)" EX 5 >/dev/null
echo "2) after flag    attacker=$(hit attacker)  user=$(hit user)   (flagged $ATTACKER_IP, TTL 5s)"
sleep 6
echo "3) after TTL     attacker=$(hit attacker)  user=$(hit user)"
dc stop redis >/dev/null
echo "4) redis down    attacker=$(hit attacker)  user=$(hit user)   (fail-open)"
dc start redis >/dev/null
