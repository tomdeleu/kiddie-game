# Fetching reference material into this repo

How to get outside material onto disk from a Claude Code session, and — more
usefully — what will not work, so nobody burns an hour rediscovering it.

## The constraint

The remote sandbox has a **network allowlist**. Almost every content host is
refused at the egress proxy with a 403 on CONNECT. Confirmed blocked:

`wallpapers.com` · `upload.wikimedia.org` · `tr.rbxcdn.com` ·
`images.rbxcdn.com` · `itch.io` · `i.ytimg.com` · `i.pinimg.com` ·
`devforum.roblox.com` · `d8j0ntlcm91z4.cloudfront.net` (the Higgsfield CDN)

Confirmed reachable: **`storage.googleapis.com`**.

Diagnose with:

```sh
curl -sS "$HTTPS_PROXY/__agentproxy/status" | head -40
```

It lists `recentRelayFailures` with the exact host and reason, which is faster
than guessing at a `000` exit code.

## What Firecrawl can and cannot do

Firecrawl is **connected and working** — no setup needed. But it is a *web
content* API, not a file downloader. Setting expectations correctly:

| Want | Works? | How |
|---|---|---|
| Page text / markdown | Yes | `firecrawl_scrape`, `formats: ["markdown"]` |
| Page HTML, links | Yes | `formats: ["html"]` / `["links"]` |
| PDFs, office documents | Yes | handled natively |
| Structured fields off a page | Yes | `formats: ["json"]` with a schema |
| Finding images | Yes | `firecrawl_search`, `sources: [{type:"images"}]` — returns URLs |
| **Downloading an image / zip / binary** | **No** | refused outright |
| A picture of a page | Yes | `formats: ["screenshot"]` — see below |

Scraping a binary URL fails explicitly:

> The URL returned a file type that Firecrawl cannot process: image/jpeg.
> Binary files like images, videos, executables, and archives are not supported.

So Firecrawl finds and describes assets; it does not fetch them.

## The one route that gets pixels onto disk

`firecrawl_scrape` with `formats: ["screenshot"]` writes a PNG to a signed
**`storage.googleapis.com`** URL — and that host is allowlisted, so `curl` can
save it.

```
firecrawl_scrape({
  url: "https://example.com/page",
  formats: ["screenshot"],
  screenshotOptions: { fullPage: true, quality: 85,
                       viewport: { width: 1280, height: 1400 } },
  waitFor: 3000
})
```

then

```sh
curl -s -o out.png --max-time 40 "<the returned storage.googleapis.com URL>"
file out.png    # verify it is really a PNG, not an error page
```

Caveats worth knowing up front:

- You get a **page** screenshot — browser chrome, cookie banners and all. Fine
  for judging a style, useless as a clean asset.
- The signed URL **expires**. Download it in the same session.
- `fullPage: true` on a long page produces very tall images (one thread here
  came out 1280×9726).
- Unauthenticated Firecrawl is **concurrency-limited**. Parallel scrapes get
  throttled with a warning and simply take longer.

## Getting more out of Firecrawl

The connector works unauthenticated but only exposes Search, Scrape and Parse,
with usage limits. Connecting an account or API key raises the limits and
unlocks the rest — `firecrawl_crawl` for whole sites, monitors, and the research
tools.

That is done in **claude.ai connector settings**, not from a session — a remote
session like this one cannot run an OAuth flow.

## Better alternatives, when they apply

Reach for these before the screenshot route:

- **Ask for a URL, download it yourself** — if the host happens to be
  allowlisted, plain `curl` is far better than a screenshot.
- **Generate the asset** via the Higgsfield connector. Owned outright, no
  copyright question, and reproducible from a recorded prompt + seed.
- **Find a CC0 source.** How [Kenney's kits](https://kenney.nl/assets) were
  found — and they turned out to be better than any reference screenshot,
  because they are usable models rather than pictures of models.

## Copyright

Third-party screenshots in [`moodboard/`](moodboard/) are **reference only**.
Do not ship them, do not redistribute them. Each is attributed to its source in
that folder's README. CC0 material is exempt and marked as such.
