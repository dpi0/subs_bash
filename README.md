# `subs_bash`

Fetch subtitles using Subdl. Only movies for now :|

## How to Use?

Get the TMDB API Key from <https://developer.themoviedb.org/docs/getting-started>.

And Subdl API Key from <https://subdl.com/api-doc>.

Run with an input file

```bash
SUBDL_API_KEY=ABC TMDB_API_KEY=XYZ subs_bash.sh "/path/to/Mind.Game.2004.1080p.BluRay.x264.mp4"

# to a desination directory
SUBDL_API_KEY=ABC TMDB_API_KEY=XYZ DEST_DIR="/path/to/subs" subs_bash.sh "/path/to/Mind.Game.2004.1080p.BluRay.x264.mp4"
```

Places extracted `.srt` files in `$PWD` by default unless `$DEST_DIR` is provided.

Without an input file

```bash
SUBDL_API_KEY=ABC TMDB_API_KEY=KEY subs_bash.sh "Inception"

# with year
SUBDL_API_KEY=ABC TMDB_API_KEY=KEY MOVIE_YEAR=2010 subs_bash.sh "inception"
```

You can place an `.env` file next to `subs_bash.sh`. See `.env.example` for reference.

```bash
MOVIE_YEAR=2010 subs_bash.sh "inception"
```

## Requirements

`jq` > 1.5 (for the `walk` function), `curl`, `fzf`, `unzip`, `awk`.
