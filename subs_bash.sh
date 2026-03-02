#!/usr/bin/env bash

help() {
  cat <<EOF
Usage: $(basename "$0") <movie-name|movie-file-path>
EOF
}

[[ $# -eq 0 ]] && {
  help
  exit 1
}

INPUT_MOVIE="$1"
MOVIE_YEAR="${MOVIE_YEAR:-}"
TMDB_API_KEY="${TMDB_API_KEY:-}"
SUBDL_API_KEY="${SUBDL_API_KEY:-}"
DEST_DIR="${DEST_DIR:-.}" # Use $PWD is no destination directory specified
C_RED='\e[31m'
C_RESET='\e[0m'

die() {
  printf "${C_RED}Error: %s Exiting...${C_RESET}\n" "$1" >&2
  exit 1
}

for cmd in curl jq fzf awk unzip; do command -v "$cmd" >/dev/null 2>&1 || die "$cmd is not installed."; done
[[ -f "$INPUT_MOVIE" ]] && DEST_DIR=$(dirname "$INPUT_MOVIE")
[[ -z "$TMDB_API_KEY" ]] && die "Required TMDB_API_KEY. Read the docs: https://developer.themoviedb.org/docs/getting-started."
[[ -z "$SUBDL_API_KEY" ]] && die "Required SUBDL_API_KEY. Read the docs: https://subdl.com/api-doc."

parse_movie() {
  local filename="${1##*/}"                           # extract only filename from path (can use basename "$1" as well)
  local match_pattern='^(.*[^0-9])?((19|20)[0-9]{2})' # to split filename in 2 parts, 1 = everything before year & 2 = year

  if [[ "$filename" =~ $match_pattern ]]; then
    local name="${BASH_REMATCH[1]}"
    local year="${BASH_REMATCH[2]}"
  else                          # when no year was present in the filename, we use just the movie name (mostly enough for TMDB)
    local name="${filename%.*}" # remove atleast the extension from filename
    local year=""
  fi

  name="${name//[._()\[\]-]/ }" # replace (./_/()/[]/- with single space -- cleaning up movie name)
  echo "$name|$year"
}

get_tmdb_id() {
  local api_key="$1" movie_name="$2" movie_year="$3"

  response=$(curl -sG "https://api.themoviedb.org/3/search/movie" \
    --data-urlencode "api_key=${api_key}" \
    --data-urlencode "query=${movie_name}" \
    --data-urlencode "year=${movie_year}" \
    --data-urlencode "include_adult=false" \
    --data-urlencode "language=en-US" \
    --data-urlencode "page=1")

  # sort the array by .vote_count and extract 4 fields from each item - id, title, release date, overview and pass this to fzf
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

get_sub_url() {
  local api_key="$1" tmdb_id="$2" response selection

  response=$(curl -sG "https://api.subdl.com/api/v1/subtitles" \
    --data-urlencode "api_key=$api_key" \
    --data-urlencode "tmdb_id=$tmdb_id" \
    --data-urlencode "type=movie" \
    --data-urlencode "languages=EN")

  # from the subtitles array, extract 4 items - download url, name, language, subdl page url, author and pass this to fzf
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

download_subs() {
  local urls="$1" dest_dir="$2"
  for url in $urls; do
    local zip_file="${url##*/}"
    echo "Downloading and extracting: $url"
    curl -sLO "$url" &&
      unzip -oqj "$zip_file" -d "$dest_dir" &&
      rm "$zip_file"
  done
}

IFS="|" read -r movie_name movie_year <<<"$(parse_movie "$INPUT_MOVIE")"

[[ -n "$MOVIE_YEAR" ]] || MOVIE_YEAR="$movie_year"

tmdb_id=$(get_tmdb_id "$TMDB_API_KEY" "$movie_name" "$MOVIE_YEAR") || die "No selection made."

subdl_url=$(get_sub_url "$SUBDL_API_KEY" "$tmdb_id") || die "No subtitle selected."

download_subs "$subdl_url" "$DEST_DIR"
