# `subs_bash`

Fetch subtitles using Subdl. Only movies for now :|

## How to Use?

Run with an input file

```bash
SUBDL_API_KEY=ABC TMDB_API_KEY=XYZ subs_bash.sh "/path/to/Mind.Game.2004.1080p.BluRay.x264.mp4"
```

Places extracted `.srt` files right next to `input_file`.

Without an input file

```bash
SUBDL_API_KEY=ABC TMDB_API_KEY=KEY MOVIE_NAME="Mind Game" subs_bash.sh

# with year
SUBDL_API_KEY=ABC TMDB_API_KEY=KEY MOVIE_NAME=Inception MOVIE_YEAR=2010 subs_bash.sh
```

Places extracted `.srt` files in `$PWD`.
