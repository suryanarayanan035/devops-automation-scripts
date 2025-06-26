#!/bin/bash

# Usage info
if [ -z "$1" ]; then
  echo "Usage: $0 <pod-name-pattern> [namespace]"
  exit 1
fi

pattern=$1
namespace=$2

# Colors for each pod
colors=(31 32 33 34 35 36)
pids=()
i=0

# Trap Ctrl+C and clean up
trap "echo -e '\nStopping logs...'; kill ${pids[*]} 2>/dev/null; exit 0" SIGINT

# Build kubectl get pods command
if [ -z "$namespace" ]; then
  pods=$(kubectl get pods --no-headers | awk -v pat="$pattern" '$1 ~ pat {print $1}')
else
  pods=$(kubectl get pods -n "$namespace" --no-headers | awk -v pat="$pattern" '$1 ~ pat {print $1}')
fi

if [ -z "$pods" ]; then
  echo "No pods found matching pattern '$pattern'"
  exit 1
fi

# Tail logs for each matching pod
for pod in $pods; do
  color=${colors[$i % ${#colors[@]}]}
  if [ -z "$namespace" ]; then
    kubectl logs -f "$pod" --all-containers=true |
      sed "s/^/$(printf '\033[%sm[%s]\033[0m ' "$color" "$pod")/" &
  else
    kubectl logs -n "$namespace" -f "$pod" --all-containers=true |
      sed "s/^/$(printf '\033[%sm[%s]\033[0m ' "$color" "$pod")/" &
  fi
  pids+=($!)
  ((i++))
done

wait
