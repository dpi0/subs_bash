#!/usr/bin/env bash

INPUT_MOVIE="$1"
MOVIE_NAME="${MOVIE_NAME:-}"
MOVIE_YEAR="${MOVIE_YEAR:-}"
TMDB_API_KEY="${TMDB_API_KEY:-}"
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

[[ -z "$TMDB_API_KEY" ]] && die "Required TMDB_API_KEY. Read the docs: https://developer.themoviedb.org/docs/getting-started."

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

req_get_id() {
  local api_key="$1"
  local movie_name="$2"
  local movie_year="$3"

  local response
  response=$(curl -sG "https://api.themoviedb.org/3/search/movie" \
    --data-urlencode "api_key=${api_key}" \
    --data-urlencode "query=${movie_name}" \
    --data-urlencode "year=${movie_year}" \
    --data-urlencode "include_adult=false" \
    --data-urlencode "language=en-US" \
    --data-urlencode "page=1")

  echo "$response" | jq -r '.results[0].id // empty'
}

[[ -n "$INPUT_MOVIE" ]] && parse_movie "$INPUT_MOVIE"

[[ -z "$MOVIE_NAME" ]] && die "Empty MOVIE_NAME. Must be a string like 'Inception'."
[[ -z "$MOVIE_YEAR" ]] && die "Empty MOVIE_YEAR. Must be an integer like 2010."

echo "$MOVIE_NAME"
echo "$MOVIE_YEAR"

req_get_id "$TMDB_API_KEY" "$MOVIE_NAME" "$MOVIE_YEAR"
