**22 · Runtime**

# Maps with OpenStreetMap

> OpenStreetMap removes a proprietary dependency and replaces it with an obligation: you are now responsible for tiles, for attribution, and for not abusing a volunteer-funded service. The single most-repeated bug in this area — a grey basemap — has four distinct causes, and knowing all four is the difference between fixing it once and fixing it nine times.

**Chunk prefix** map **Updated** 2026-08-01 **Depends on** 01 Foundations · 06 Caching

#### On this page

1. [Why OSM, and what it obliges you to](#why)
1. [The tile usage policy](#policy)
1. [A caching tile proxy](#proxy)
1. [The four grey-tile pathologies](#greytile)
1. [One hardened tile layer](#onelayer)
1. [Camera lifecycle](#camera)
1. [Markers, clustering and price pins](#markers)
1. [Adding your own data](#overlays)
1. [Geocoding and routing](#geocoding)
1. [Offline maps](#offline)
1. [Contributing data back to OSM](#contributing)

<!-- chunk: map.why | tags: openstreetmap,licensing,attribution -->

## Why OSM, and what it obliges you to

OpenStreetMap is the only mapping stack that is simultaneously free of a proprietary SDK, redistributable, and good enough almost everywhere. That combination is what makes a libre build possible at all.

| Gain | Obligation |
| --- | --- |
| No proprietary services dependency — a prerequisite for a libre build | You supply the tiles, or arrange for someone to |
| No per-request billing | You must not abuse the free community tile service |
| Data you may redistribute and derive from | **Attribution is a licence condition, not a courtesy** |
| You can fix the map itself | Improvements you make to the data belong to everyone |

> **[RULE]**

> **Attribution is mandatory and must be visible on the map surface.** The data licence requires crediting OpenStreetMap contributors wherever the map is shown. A line in an about screen is not sufficient — put it on or immediately adjacent to the map, and make it a tappable link to the copyright page. It costs one widget and it is a licence term.

> ```dart
> RichAttributionWidget(
>   attributions: [
>     TextSourceAttribution(
>       'OpenStreetMap contributors',
>       onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
>     ),
>   ],
> )
> ```

<!-- chunk: map.policy | tags: tiles,policy,rate-limiting -->

## The tile usage policy

The community tile servers are donated infrastructure with a published usage policy. A mobile app with real users is, by default, exactly the kind of consumer that policy is written to constrain.

| Requirement | What it means for an app |
| --- | --- |
| **A valid, identifying User-Agent** | Not the default HTTP client string. Include an application identifier and a contact URL. |
| **Cache aggressively** | Do not re-fetch a tile you already have. Both an on-device cache and an upstream cache. |
| **No bulk downloading** | No pre-fetching whole regions from the community servers. |
| **Heavy use should be self-hosted** | Beyond modest volume, run your own tiles or a proxy in front |
| Blocking is real | Non-compliant clients get blocked by User-Agent, which presents to your users as a permanently grey map |

> **[RULE]**

> **Use a stable, version-free, contact-carrying User-Agent.** Version-free matters: a string containing your app version changes on every release, which looks to a rate limiter like a fleet of distinct clients and defeats any per-client reputation. Set one identifier for the life of the application.

> ```text
> de.example.tile-proxy/1.0 (+https://github.com/org/app)
> ```

> **[WHY]**

> The failure mode is delayed and total. You ship, usage grows, and at some point the tile service blocks your identifier — at which point every user has a grey map, simultaneously, with no error visible in your own monitoring. It is not a gradual degradation you notice in time. Get the User-Agent and the caching right before you have users, not after.

<!-- chunk: map.proxy | tags: tiles,proxy,caching,edge-function -->

## A caching tile proxy

The clean answer to the policy is a thin proxy you control, sitting between the app and the upstream tile server.

```text
app  →  https://your-backend/functions/v1/tiles/{z}/{x}/{y}.png
            ├─ validates z/x/y bounds  (not an open relay)
            ├─ sets ONE stable upstream User-Agent with a contact URL
            ├─ caches 7 days at the edge (Cache-Control + CDN-Cache-Control)
            └─ propagates upstream errors as-is, never caching them
        →  https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

| Property | Why |
| --- | --- |
| **Bounds validation** (`z ∈ 0..19`, `x,y ∈ 0..2^z−1`) | Without it your proxy is an open relay onto the tile service and your identifier is what gets blocked. Out-of-range coordinates return a client error without touching upstream. |
| **One server-side User-Agent** | Upstream sees one well-behaved client instead of every user's device. This is the single largest compliance improvement available. |
| **A long edge cache** | A week is reasonable for a basemap. Set both the standard and the CDN-specific cache headers so intermediate caches honour it. |
| **Errors are propagated, never cached** | Caching a transient upstream failure pins a grey tile for the whole cache lifetime — the worst possible outcome |
| **Keep the direct URL as a fallback** | If the proxy URL is unset or misconfigured, degrade to direct rather than to grey. A misconfigured build should still render a map. |
| **On-device cache stays on** | Its TTL stacks on top of the edge cache. Two layers, different failure modes. |

> **[CHECK]**

> Verify the proxy is actually caching by requesting the same tile twice and reading the cache-status header. A proxy that forwards every request is worse than no proxy: it adds a hop and still hammers upstream, while making you believe you are compliant.

<!-- chunk: map.greytile | tags: tiles,bugs,root-cause -->

## The four grey-tile pathologies

> **[TRAP]**

> **Symptom: the basemap renders as grey squares — intermittently, on some devices, unreproducibly.** This is the most-recurring bug in this whole subject area. One project "fixed" it **nine times** across two months of issues before stopping to enumerate the causes, because several distinct failures produce an identical grey square. Any one fix appears to work and the bug returns.

> The four causes, all of which must be addressed:

1. **Transient upstream errors** — rate-limit or server errors on individual tiles. *Fix:* a tile provider that retries with jittered backoff.
1. **The pan-fetch race** — panning queues fetches for tiles that scroll off-screen, and the backlog starves the visible ones. *Fix:* abort obsolete requests so in-flight fetches for off-screen coordinates are cancelled.
1. **The error-tile cache trap** — a failed tile is remembered as failed and never retried. *Fix:* an eviction strategy that drops failed tiles once they leave the viewport, so the next pan retries cleanly.
1. **Grey while loading** — the previous zoom level's painted tiles are discarded before the new ones arrive. *Fix:* a wider keep-buffer so the old level stays painted during the swap.

> A fifth, related one: a **cold-start camera race**, where tiles are requested before the layout has settled and the resulting fetches are for the wrong viewport. *Fix:* allow a parent to trigger a tile reset once its layout settles.

> **[RULE]**

> **This is the canonical case for the regression-escalation protocol.** When a symptom recurs after a fix, stop patching and enumerate every code path that can produce it — the grey tile is one pixel pattern with five upstream causes. Fixing them one at a time, each time believing you are done, is how two months disappear. See [page 03](03-tdd-and-testing.html#recurrence).

<!-- chunk: map.onelayer | tags: architecture,tiles,widget -->

## One hardened tile layer

The architectural fix that ended the recurrence: **exactly one** way to instantiate a tile layer in the codebase, carrying all the mitigations, enforced by a lint test.

```dart
/// The ONLY legitimate way to create a TileLayer in this codebase.
/// Every mitigation for the documented grey-tile pathologies lives here,
/// so no call site can accidentally omit one.
class HardenedTileLayer extends StatelessWidget {
  const HardenedTileLayer({super.key, this.reset});

  /// Lets a parent fire a tile reset when its layout settles
  /// (the cold-start camera race).
  final Stream<void>? reset;

  @override
  Widget build(BuildContext context) => TileLayer(
        urlTemplate: AppConstants.tileUrl,          // proxy, or direct fallback
        userAgentPackageName: AppConstants.tileUserAgent,
        tileProvider: RetryNetworkTileProvider(),   // (1) jittered retry
        // (2) upstream default, restored deliberately after a regression
        abortObsoleteRequests: true,
        // (3) failed tiles are dropped once off-screen
        evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
        // (4) keep the previous level painted during a zoom swap
        keepBuffer: 4,
        reset: reset,
      );
}
```

> **[WHY]**

> Before the wrapper, six of seven tile-layer call sites used the default provider with no mitigations. Trip detail, the trajectory map, the driving view and the radius picker all rendered grey on a transient upstream glitch — while the main map, which had been patched repeatedly, appeared fine. Every previous fix had patched one surface in isolation. A convention that six of seven sites do not follow is not a convention; a widget plus a lint test asserting no direct instantiation is.

> **[RULE]**

> **The retry provider owns an HTTP client that must live for the visible lifetime of the layer.** Recreating the client on rebuild cancels in-flight fetches and produces exactly the grey tiles it was written to prevent. Hold it in the state, not in `build`, and add a lint test pinning the call sites so a future refactor cannot quietly regress it.

<!-- chunk: map.camera | tags: camera,lifecycle,flutter-map -->

## Camera lifecycle

The second half of the grey-map problem is the camera. Imperative camera manipulation during build and layout is a reliable source of races.

| Do | Instead of |
| --- | --- |
| Declare the initial view with a camera-fit option in the map options | Calling a fit method imperatively after the first frame |
| One guarded re-fit when the bounds genuinely change, in the did-update lifecycle | Re-fitting on every rebuild |
| Keep the map state alive when it is inside a tab or a page view | Letting it rebuild from scratch on every tab switch |
| Guard the re-fit on an actual bounds change | An unguarded re-fit, which fights the user's pan |

> **[TRAP]**

> **Symptom: the map jumps back to its initial position while the user is panning.** An unguarded re-fit in the did-update lifecycle fires on a rebuild caused by something unrelated — a provider emitting, a parent rebuilding — and yanks the camera. Compare the incoming bounds against the last-applied bounds and return early if unchanged. Users experience this as the map "fighting" them and it reads as a serious quality defect.

A related simplification worth taking: delete any bespoke cold-start reset window — a timer that resets the map for some seconds after launch to "handle" the camera race. It is a band-aid over the layout-settled problem, it is timing-dependent, and the declarative camera fit plus a settle-triggered reset stream replaces it entirely.

<!-- chunk: map.markers | tags: markers,clustering,performance -->

## Markers, clustering and price pins

Thousands of markers will not render acceptably. Cluster them, and keep each marker cheap.

| Concern | Practice |
| --- | --- |
| **Clustering** | A clustering layer above a threshold. Tune the radius by zoom — aggressive when zoomed out, off when zoomed in. |
| **Marker cost** | A marker is a widget rendered for every visible pin. Keep it to a container plus text; no images decoded per marker, no shadows, no per-marker providers. |
| **Viewport culling** | Only build markers within the visible bounds plus a margin. Do not hand the layer ten thousand markers and hope. |
| **Colour encoding** | A green-to-red scale for a value, with a legend. Never colour alone — pair it with the number, for accessibility and for precision. |
| **Tap targets** | The visual pin can be small; the tappable area must meet the platform guideline. Wrap in a larger transparent hit area. |
| **Selection** | Render the selected marker in a separate layer above the cluster layer, or clustering will swallow it. |

> **[TRAP]**

> **Symptom: markers render a placeholder such as `--` where a value is expected, even though the underlying record has data.** The marker asked for one specific field and that field was null, while a usable value existed elsewhere on the record. Write a single resolver that returns the best available value with a documented precedence, and have every surface use it — the marker, the list row, the detail screen. One project added exactly such a resolver so a record with *any* usable value can never render as a placeholder.

> **[RULE]**

> **Do not re-sort or re-cluster a visible list as asynchronous enrichment arrives.** Markers jumping under the user's finger is worse than a slightly stale order. Display the enriched value per item immediately; change the ordering only when the enriching data source is complete and stable — and say in the issue that this is a deliberate boundary, or someone will "fix" it later.

<!-- chunk: map.overlays | tags: layers,polylines,data-visualisation -->

## Adding your own data

The basemap is a backdrop. Everything you actually want to show goes in layers on top, and the layer order is the composition.

```dart
FlutterMap(
  options: MapOptions(initialCameraFit: fit),
  children: [
    const HardenedTileLayer(),                    // 1. basemap
    PolygonLayer(polygons: zones),                // 2. areas
    PolylineLayer(polylines: routeSegments),      // 3. lines
    CircleLayer(circles: [accuracyCircle]),       // 4. radii
    MarkerClusterLayerWidget(options: clusters),  // 5. clustered points
    MarkerLayer(markers: [selected, userPosition]), // 6. always-on-top points
    const MapAttribution(),                       // 7. REQUIRED
  ],
)
```

| What you want to show | Layer | Notes |
| --- | --- | --- |
| A route or a recorded track | Polyline | Split into segments to colour by a per-segment value — speed, efficiency, elevation |
| A search radius or GPS accuracy | Circle | Circles take metre radii, so they scale correctly with zoom, unlike a fixed-pixel marker |
| A region, a boundary, a zone | Polygon | Semi-transparent fill plus a solid stroke |
| Points of interest | Marker, clustered | See above |
| A heat pattern | Overlay image, or many low-opacity circles | Pre-compute the raster; do not draw thousands of widgets |
| A second raster source | A second tile layer with opacity | Terrain shading, a cycling layer, your own generated tiles |
| Custom drawing | A widget layer with a custom painter | The escape hatch for anything the built-in layers cannot express |

> **[RULE]**

> **Colour-code a track by segment, not by whole route.** A single-colour polyline shows where you went; a segment-coloured one shows *where the interesting thing happened*, which is usually the actual question. Build the polyline as many short segments, each with a colour derived from its own value, and always ship a legend — an unlabelled colour scale is decoration.

For a track, downsample before rendering. A recording at one sample per second produces tens of thousands of points for a long trip; rendering them all costs frames and shows nothing a simplified line does not. Apply a line-simplification pass at display time and keep the full-resolution data for analysis.

<!-- chunk: map.geocoding | tags: nominatim,geocoding,routing,osrm -->

## Geocoding and routing

Two adjacent services in the same ecosystem, each with its own usage policy that is stricter than the tile one.

| Service | Does | Policy |
| --- | --- | --- |
| **Nominatim** | Address ↔ coordinate | Absolute maximum one request per second; identifying User-Agent; cache results; no bulk use. Heavier use means self-hosting. |
| **OSRM** | Routing, plus a distance/duration matrix | The demo server is for development. Self-host for production. |
| **Overpass** | Querying raw OSM data | Rate-limited and shared; cache heavily; never in a user-facing hot path. |
| **Platform geocoding** | Address ↔ coordinate, on-device | No network policy, but availability and quality vary — good as a first tier |

> **[RULE]**

> **Put every one of these behind the service chain with a long cache TTL.** Geocoding results are effectively immutable — cache them for a week. Route geometry between two fixed points is stable for hours. The chain from [page 01](01-foundations-architecture.html#service-chain) gives you fresh-first reads, stale fallback and per-source rate limiting without any of it being reimplemented per service, and it is what makes a one-request-per-second policy survivable.

> **[WHY]**

> One project needed real road distances to many destinations and found it required no new service at all: the routing instance already used for route planning exposes a matrix endpoint — one origin, many destinations, one request. The same lesson had already occurred with a points-of-interest backend. The second feature on an existing backend is usually one endpoint away, and checking costs ten minutes.

<!-- chunk: map.offline | tags: offline,caching,storage -->

## Offline maps

Three levels, with very different costs.

| Level | Mechanism | Cost |
| --- | --- | --- |
| **Incidental** | The on-device tile cache retains what the user has already viewed | Free. Covers "I was just here and lost signal". |
| **Region download** | The user selects an area; you fetch its tiles for a zoom range | Storage, plus a policy problem — bulk downloading from the community servers is forbidden. Only do this against tiles you serve. |
| **Bundled vector tiles** | A packaged vector tile file rendered on-device | Largest engineering cost; smallest data footprint; genuine full offline |

> **[RULE]**

> **Never bulk-download from the community tile servers.** It is explicitly prohibited and it is the fastest way to get your identifier blocked, which grey-maps every user at once. If you want region download, it must come from tiles you host — which makes the proxy in [§Proxy](#proxy) a prerequisite for the feature, not an optimisation.

Whatever the level, tell the user what is cached and let them clear it. Map tiles are usually the largest thing your app stores, and an app that silently occupies a gigabyte gets uninstalled.

<!-- chunk: map.contributing | tags: osm,contributing,editing,data-quality -->

## Contributing data back to OSM

If your app surfaces places, you will find places the map does not have — or has wrong. Fixing them upstream improves the map for everyone, and for you permanently.

### How to add or correct information

| Tool | Best for |
| --- | --- |
| **iD** — the browser editor at openstreetmap.org | Adding or fixing a single point. No installation, guided, hard to break anything. |
| **Vespucci** / **Go Map!!** — mobile editors | Surveying on the spot, standing in front of the thing you are mapping |
| **JOSM** — the desktop editor | Larger or repetitive edits, with validation and plugins |
| **Overpass Turbo** | Not an editor — a query tool. Use it to find what is missing or inconsistent before editing. |

The workflow is the same regardless of tool: sign in with an OSM account, place or select the object, choose a preset, fill in the tags, and upload as a **changeset** with a comment describing the change and its source.

### Tagging, briefly

OSM data is nodes, ways and relations, each carrying free-form `key=value` tags. Conventions are documented on the OSM wiki and are the difference between data everyone can use and data nobody can query.

```text
# A fuel station, tagged conventionally
amenity=fuel
brand=…
operator=…
opening_hours=Mo-Su 06:00-22:00
fuel:diesel=yes
fuel:octane_95=yes
payment:cash=yes
payment:debit_cards=yes

# An EV charging point
amenity=charging_station
socket:type2=2
socket:type2:output=22 kW
capacity=2
```

> **[RULE]**

> **Never bulk-import your app's data into OSM, and never edit from your app automatically.** Automated and imported edits are governed by a community process that requires prior discussion and approval, and an unapproved import will be reverted and will damage your standing. If you want to help, the right shape is: let your users report a discrepancy, and either fix it yourself as a human-reviewed edit, or hand the user a deep link into an editor pre-positioned at that location.

```dart
/// Deep-link a user into the browser editor at the right place, so a
/// "this is wrong" report can become a real fix in about a minute.
Uri osmEditLink(double lat, double lon) => Uri.parse(
  'https://www.openstreetmap.org/edit#map=19/$lat/$lon',
);
```

### What is worth contributing

- **Missing objects you have verified in person.** The strongest kind of contribution.
- **Opening hours**, which are chronically incomplete and highly useful.
- **Attribute detail** — which fuel grades, which connector types, which payment methods — where you have first-hand knowledge.
- **Corrections** to something you found wrong on the ground.

> **[WHY]**

> OSM's data quality rests on a norm: you map what you have observed or what comes from a licence-compatible source. Copying from a proprietary map is a licence violation that poisons the data. Inferring from your own aggregated dataset may be fine or may be an import requiring discussion, depending on the source's licence and the scale — ask before doing it, not after.

> **[CHECK]**

> Before reporting that upstream data is missing, verify against the *authoritative* source rather than your own parser's interpretation of it. One project told a user a location had no opening hours because its parser discarded a particular range as degenerate — the upstream's own interface displayed those hours correctly, because that range is a convention meaning "always open". The test asserting the discard was part of the bug. This applies to OSM as much as to any other feed.

#### Sources for this page

- One project's map reimplementation and its decision record: the single hardened tile-layer wrapper carrying all four grey-tile mitigations, the declarative camera fit replacing an imperative reset window, the best-available-value resolver so a marker never renders a placeholder, and the lint test pinning the tile-provider call sites.
- Its tile-proxy design: bounds validation to prevent open relaying, a stable version-free contact-carrying upstream User-Agent, a seven-day edge cache with matching CDN headers, error propagation without caching, and the direct URL retained as a documented fallback.
- The recorded history of the grey-tile bug — nine fixes across two months, and the finding that six of seven tile-layer call sites bypassed every mitigation — plus the discovery that an existing routing backend's matrix endpoint removed the need for a new service.
- Its opening-hours parser incident, which supplies the verify-against-the-authority check.

The OSM usage policies, the tagging examples and the contribution workflow are from the OpenStreetMap project's own published conventions rather than from either codebase. Verify current policy details against the OSM wiki before relying on a specific limit.
