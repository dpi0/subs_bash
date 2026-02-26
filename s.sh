#!/usr/bin/env bash

INPUT_MOVIE="$1"
MOVIE_NAME="${MOVIE_NAME:-}"
MOVIE_YEAR="${MOVIE_YEAR:-}"
TMDB_API_KEY="${TMDB_API_KEY:-}"
SUBDL_API_KEY="${SUBDL_API_KEY:-}"
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
[[ -z "$SUBDL_API_KEY" ]] && die "Required SUBDL_API_KEY. Read the docs: https://subdl.com/api-doc."

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

  response=$(curl -sG "https://api.themoviedb.org/3/search/movie" \
    --data-urlencode "api_key=${api_key}" \
    --data-urlencode "query=${movie_name}" \
    --data-urlencode "year=${movie_year}" \
    --data-urlencode "include_adult=false" \
    --data-urlencode "language=en-US" \
    --data-urlencode "page=1")

  selection=$(echo "$response" | jq -r '
    .results
    | sort_by(.vote_count) | reverse | .[]
    | [
        .id,
        .title,
        (.release_date[0:4] // "N/A"),
        (.overview[0:120] | gsub("\n"; " "))
      ]
    | join(" | ")
    ' | fzf --header "Select Movie (Sorted by Votes): Movie Name | Year | Description" \
    --delimiter ' \| ' \
    --with-nth "2.." \
    --preview-window=hidden) ||
    return 1

  echo "$selection" | awk -F ' \\| ' '{print $1}'
}

req_get_sub_url() {
  local api_key="$1" tmdb_id="$2"
  local response selection

  response=$(curl -sG "https://api.subdl.com/api/v1/subtitles" \
    --data-urlencode "api_key=$api_key" \
    --data-urlencode "tmdb_id=$tmdb_id" \
    --data-urlencode "type=movie" \
    --data-urlencode "languages=EN")

  selection=$(echo "$response" | jq -r '
    if .status == true then
      .subtitles[] | [
        .url,
        .release_name,
        .language,
        .subtitlePage,
        .author
      ] | join(" | ")
    else
      empty
    end
  ' | fzf -m --header "Select Subtitle: Release | Language | Page | Author" \
    --delimiter ' \| ' \
    --with-nth "2.." \
    --preview-window=hidden) || return 1

  echo "$selection" | awk -F ' \\| ' '{print "https://dl.subdl.com" $1}'
}

[[ -n "$INPUT_MOVIE" ]] && parse_movie "$INPUT_MOVIE"

[[ -z "$MOVIE_NAME" ]] && die "Empty MOVIE_NAME. Must be a string like 'Inception'."
[[ -z "$MOVIE_YEAR" ]] && die "Empty MOVIE_YEAR. Must be an integer like 2010."

TMDB_ID=$(req_get_id "$TMDB_API_KEY" "$MOVIE_NAME" "$MOVIE_YEAR") || die "No selection made."

SUB_URL=$(req_get_sub_url "$SUBDL_API_KEY" "$TMDB_ID") || die "No subtitle selected."
echo "$SUB_URL"
