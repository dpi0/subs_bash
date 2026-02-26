#!/usr/bin/env bash

INPUT_MOVIE="$1"
MOVIE_NAME="${MOVIE_NAME:-}"
MOVIE_YEAR="${MOVIE_YEAR:-}"
C_RED=196

c_echo() {
  local code="$1"
  shift
  printf "$(tput setaf "$code")%s$(tput sgr0)\n" "$*"
}

die() {
  c_echo "$C_RED" "Error: $1 Exiting..."
  exit 1
}

parse_movie() {
  local file name year
  file="${1##*/}"

  # look for the first 4-digit year (19xx or 20xx)
  if [[ "$file" =~ ^(.*[^0-9])?((19|20)[0-9]{2}) ]]; then
    name="${BASH_REMATCH[1]}"
    year="${BASH_REMATCH[2]}"

    # cleanup
    name="$(echo "$name" | tr '._()[]-' ' ')"
    name=$(echo "$name" | xargs)

    MOVIE_NAME="$name"
    MOVIE_YEAR="$year"
  fi
}

[[ -n "$INPUT_MOVIE" ]] && parse_movie "$INPUT_MOVIE"

[[ -z "$MOVIE_NAME" ]] && die "Empty MOVIE_NAME. Must be a string like 'Inception'."
[[ -z "$MOVIE_YEAR" ]] && die "Empty MOVIE_YEAR. Must be an integer like 2010."

echo "$MOVIE_NAME"
echo "$MOVIE_YEAR"
