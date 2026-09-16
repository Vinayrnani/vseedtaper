#!/bin/bash
# Keep only 25 newest screenshots, delete older ones
DIR="screenshots"
MAX=25
if [ -d "$DIR" ]; then
  COUNT=$(ls -1 "$DIR" 2>/dev/null | wc -l)
  if [ "$COUNT" -gt "$MAX" ]; then
    ls -1t "$DIR" | tail -n +$((MAX+1)) | xargs -I {} rm -f "$DIR/{}"
    echo "Cleaned up: kept $MAX newest, removed $((COUNT-MAX)) old screenshots"
  fi
fi
