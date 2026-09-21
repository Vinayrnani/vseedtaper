#!/bin/bash
# Keep only 25 newest screenshots (by mtime), delete oldest by file modification time.
DIR="screenshots"
MAX=25
if [ -d "$DIR" ]; then
  COUNT=$(ls -1 "$DIR" 2>/dev/null | wc -l)
  if [ "$COUNT" -gt "$MAX" ]; then
    # ls -1t sorts by mtime (newest first); tail skips the 25 newest, rest are oldest → delete.
    ls -1t "$DIR" | tail -n +$((MAX+1)) | xargs -I {} rm -f "$DIR/{}"
    echo "Cleaned up: kept $MAX newest (by mtime), removed $((COUNT-MAX)) oldest screenshots"
  fi
fi
