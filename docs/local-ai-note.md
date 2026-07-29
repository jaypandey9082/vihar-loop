# Local Draft Assist evidence

## Product job and scope

Draft Assist turns one already-required Description into three editable
suggestions: Type, Title, and Category. Those fields reduce repetitive form
work without letting assistance choose the broad area, contact preference,
deadline, identity, status, timestamps, or private markers.

## User workflow

The person writes a Description and activates **Suggest type, title &
category**. The result appears as a transient preview with its source. No field
changes until **Use suggestions** is activated; **Dismiss** keeps the current
form unchanged. Applied values remain ordinary editable controls. Nothing is
posted or persisted until the normal Post action passes all form and
repository validation.

## Boundary and contract

`LocalAiService.suggestListing` receives the Description and current preferred
Kind. It returns `ListingSuggestion`, which contains only Kind, Title,
Category, and a displayable source. `main.dart` injects the same production
service through `ViharLoopApp`, `FeedScreen`, `CreateListingScreen`, and
`CreateListingViewModel`. The feed, details, Privacy & data, repository, Hive
store, and secure key store do not use or understand suggestions.

## Section 7 production implementation

`RuleBasedListingAssistant` is the production implementation. It is a
deterministic fallback; no generative model runs in Section 7. It:

1. validates the complete Description before analysis;
2. normalizes whitespace and case only for matching while preserving the
   original Unicode input;
3. scores stable Need/Offer phrases and tokens, using the selected Kind for no
   signal or equal scores;
4. scores a fixed set of category signals with an explicit stable tie order;
5. derives a concise Title from the first useful sentence, removing only
   known leading intent and trailing demo context;
6. validates the returned Title before exposing the suggestion.

Repeated words do not multiply token scores, and no clock, random value,
storage, network, log, cache, or user-input mutation participates. This gives
stable output for equal input without pretending to understand every language
or meaning.

## Validation and privacy

Input calls the existing `ListingDraftValidator.descriptionError`, so the
same length, direct-contact/payment, and precise-location rules used by the
manual form apply before any keyword analysis. Output goes through
`ListingSuggestionValidator`, which delegates Title validation to the same
`ListingDraftValidator`. Exceptions are generic and never echo rejected
content.

The preview contains no Description, location, contact, deadline, persisted
ID, origin, status, timestamp, or marker. It is not logged or cached. The
repository still validates the final `ListingDraft` immediately before
encrypted persistence.

## Failure behaviour

Only one Suggest or Post action may be pending. A second action is refused
while one is pending. A suggestion failure clears the preview, shows
non-technical friendly copy, leaves every manual value editable, and supports
retry. Leaving the screen while Suggest is pending cannot notify a disposed
view model.

## Offline and evaluation evidence

The fallback requires no model file, model runtime, hosted API, token, secret,
network permission, dependency, or environment file. Static production scans
and the release manifest audit cover that boundary. The expected guitar-capo
workflow is exercised through the real assistant and in-memory repository:
preview, explicit apply, manual edit, Post, and feed display, with no
repository call before Post.

The table-driven deterministic evaluation covers 18 required English, Hindi,
and Marathi cases across all categories plus Other. Fifteen invalid
Description classes are rejected through the shared privacy boundary.
Repeated-input testing returns identical Kind, Title, Category, and source in
10 of 10 runs. This is rule-based expected-case coverage, not model accuracy.
No latency figure is reported because no controlled device benchmark was
performed.

## Android API 36 manual evidence

An in-place debug upgrade from `0.6.0+6` to `0.7.0+7` retained the existing
nine-listing encrypted store. With airplane mode enabled, the exact
Description `Need a guitar capo for rehearsal near Somaiya today.` produced:

- Type: Need
- Title: Guitar capo for rehearsal
- Category: Music, hobbies & sports
- Source: Built-in offline rules

Dismiss removed the preview without changing the form. A second Suggest
returned the same values. Apply left the Description unchanged, applied only
Type, Title, and Category, and focused Title; the Title was then edited to
`Guitar capo for rehearsal today`. Completing the ordinary fields and
activating Post changed the feed count from nine to ten. The exact listing was
still present after force-stop/relaunch. Before Post, no record was added.

A second API 36 draft containing `Flat 302 Wing B` was rejected with the
precise-location guidance and produced no preview. The app, airplane mode,
font scale, display density, rotation, and emulator running state were restored
after verification.

## Known limitations and Section 8 integration

Fixed rules cannot infer arbitrary intent, category, or language and share the
known limits of heuristic privacy validation. Section 8 may add an actual
on-device model provider behind `LocalAiService`; the same preview, explicit
apply, output validation, repository boundary, and deterministic fallback can
remain. Model licensing/download setup, runtime benchmarking, timeouts,
model-first coordination, and actual Gemma device verification remain
pending.
