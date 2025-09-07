#!/usr/bin/env bash
set -euo pipefail
NAMESPACE=ingress-nginx
SERVICE=ingress-nginx-controller
LOCAL_PORT=18080
REMOTE_PORT=80
ADDRESS=127.0.0.1
while true; do
  echo "[port-forward] starting: $NAMESPACE svc/$SERVICE $LOCAL_PORT:$REMOTE_PORT"
  kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$REMOTE_PORT" --address="$ADDRESS" || true
  echo "[port-forward] exited; restarting in 2s..."
  sleep 2
done
