# Fetching reference material into this repo

How to get outside material onto disk from a Claude Code session, and — more
usefully — what will not work, so nobody burns an hour rediscovering it.

## The constraint

The remote sandbox has a **network allowlist**. Almost every content host is
refused at the egress proxy with a 403 on CONNECT. Confirmed blocked:

`wallpapers.com` · `upload.wikimedia.org` · `tr.rbxcdn.com` ·
`images.rbxcdn.com` · `itch.io` · `i.ytimg.com` · `i.pinimg.com` ·
`devforum.roblox.com`

Confirmed reachable: **`storage.googleapis.com`**, and — since being added to the
environment allowlist — the Higgsfield CDNs. Downloading generated assets now
works directly with `curl`; see [`fetch-plates.sh`](fetch-plates.sh).

**Allowlist changes take effect immediately.** The gateway evaluates policy per
request, so a session does *not* need restarting after the environment is
edited — contrary to what environment *variables* do, which are read once at
startup.

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

## Allowlisting a host

The block is an **environment network policy**, enforced upstream of the
container. A session cannot change it — the proxy docs say to report the blocked
host rather than route around it. It is changed on the environment itself:

1. Go to [claude.ai/code](https://claude.ai/code).
2. Click the **cloud icon showing the environment's name**, in the row above the
   message box. (There is no settings page or direct URL for this selector.)
3. Hover the environment → click the **settings icon** on its right.
4. Set **Network access** to **Custom**.
5. In **Allowed domains**, list one domain per line.
6. **Tick "Also include default list of common package managers."** Without it,
   *only* the listed domains are allowed and npm, PyPI and
   `raw.githubusercontent.com` all stop working.

A leading `*.` matches every subdomain. **Changes apply immediately** — the
gateway evaluates policy per request, so the running session picks them up
without restarting. (Environment *variables* behave differently: those are read
once at startup and do need a fresh session.)

For this project:

```text
higgsfield.ai
*.higgsfield.ai
d8j0ntlcm91z4.cloudfront.net
d1xarpci4ikg0w.cloudfront.net
```

`*.cloudfront.net` would also work and would survive Higgsfield reprovisioning
its distributions — but CloudFront is AWS's shared CDN, used by a large fraction
of the web, so that wildcard is far broader than it looks. The narrow form above
is tighter but brittle: if those distribution IDs change, downloads break and the
list needs updating.

Setting **Network access** to **Full** removes the question entirely, at the cost
of any egress restriction.

**MCP connector traffic does not go through this allowlist.** Higgsfield and
Firecrawl tool calls already work regardless; the allowlist only governs what the
container fetches directly, such as `curl`.

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
