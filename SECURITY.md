# Security Policy

## Reporting a vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities.

Preferred: use GitHub's **[private vulnerability reporting](../../security/advisories/new)**
(Security tab → "Report a vulnerability") on this repository. It reaches the maintainer directly
without exposing the report publicly, and doesn't require sharing an email address.

If private vulnerability reporting isn't available on this repository, use the contact listed
by the maintainer in the repository's GitHub profile.

<!-- Owner action: if you prefer a dedicated security contact email instead of (or in addition
     to) GitHub private reporting, replace this note with that address. Do not publish a
     placeholder email — leave this section pointing at GitHub reporting until a real one exists. -->

## What to include

- A description of the issue and its potential impact.
- Steps to reproduce, or a minimal proof of concept.
- The affected version/commit of `NFCLocatorCore` and/or `TapSense`.
- Whether the issue requires a physical device to reproduce (relevant given this project's Core
  NFC integration).

## Scope

- `NFCLocatorCore` — the published Swift package.
- `TapSense` — the sample app.

Both are client-side only: `NFCLocatorCore` has no library-owned backend, and `TapSense`'s remote
catalog source is a local fake for development (`FakeCatalogRemoteAPI`). If you're integrating a
real remote catalog endpoint in your own app, its security is your own responsibility to review;
the library's `CatalogRemoteAPI` protocol only defines the contract, not a transport
implementation.

## Response

This is a personal open-source project maintained on a best-effort basis. There is no guaranteed
response SLA. Reports will be acknowledged and triaged as soon as reasonably possible.

## Disclosure

Please allow a reasonable window to investigate and, if applicable, release a fix before any
public disclosure. Coordinated disclosure is appreciated.
