<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Additional permissions, and what you get free

Sparkilo is distributed under the **GNU Affero General Public License,
version 3 or later** ([`LICENSE`](LICENSE)), © 2026 Florian DITTGEN.

This file grants two things the AGPL alone does not, and points at the
one you buy. It is part of the licence: an additional permission under
AGPL §7, removable by any recipient who prefers the bare AGPL.

## 1. What you get free — which is almost certainly everything

If you are an **association, a collective, a public body, a school, a
fleet operator or an individual**, and equally if you are a company
willing to honour the AGPL, you need nothing from this file and nothing
from us. Run it, modify it, host it, manage your fleet with it, bill
whoever you like for the service you run with it.

The one obligation is §13: **if you modify Sparkilo and let people use
it over a network, those people must be able to get your modified
source.** Publishing a link in the app is enough.

Running Sparkilo as it ships triggers no obligation at all. Neither does
changing a logo, a colour or a configuration.

## 2. The app-store permission

> As an additional permission under section 7 of the GNU Affero General
> Public License version 3, the copyright holder grants you permission
> to convey the Program through Apple's App Store, TestFlight, Google
> Play, the Microsoft Store, F-Droid and comparable application
> distribution channels, and to accept the terms those channels impose
> on their users, notwithstanding any term of those channels that would
> otherwise conflict with sections 6, 10 or 12 of this Licence —
> including restrictions on the number of devices on which a user may
> install the Program.

**Why this exists.** The GPL family forbids imposing further
restrictions on the recipient; Apple's terms limit how many devices a
buyer may install on. That conflict is what removed VLC from the App
Store in 2011. Sparkilo ships TestFlight and App Store builds, so
without this permission the iOS leg could not exist. The exception is
narrow on purpose: it permits distribution through such a channel and
nothing else. It does not weaken §13, and it does not let anyone
withhold source.

## 3. The proprietary-library permission

> As an additional permission under section 7 of the GNU Affero General
> Public License version 3, the copyright holder grants you permission
> to combine the Program with, and to convey the resulting combined
> work linked against, the following components and their transitive
> dependencies, notwithstanding that their licences are incompatible
> with this Licence:
>
> * `com.google.android.gms` (Google Play services),
> * `com.google.mlkit` (Google ML Kit),
> * `com.google.android.play` (Google Play Core).
>
> This permission extends to those components only, by name. It grants
> nothing in respect of any other non-free component, and it does not
> relieve you of any obligation of this Licence in respect of the
> Program itself.

**Why this exists.** The Google Play build links those libraries — they
arrive through `geolocator_android` (`play-services-location`),
`google_mlkit_text_recognition` (text recognition,
`play-services-base`/`basement`) and `in_app_review` (Play Core). AGPL
plus non-free linked libraries is an incompatibility, and without this
permission the Play artifact could not be distributed at all.

**The F-Droid build does not rely on it.** That flavour strips all three
groups at the Gradle level (`gmsExcludeGroups` in
`android/app/build.gradle.kts`) and is meant to need no exception. If it
ever turns out to carry them, the answer is to remove them, not to lean
on this clause.

The permission names its components deliberately. A blanket "any
proprietary library" clause would hand away the thing §13 is protecting.

## 4. The commercial licence

If you are a **for-profit company**, you modify Sparkilo, you serve it
to people over a network, and you do not want to publish those
modifications — buy an exception:
[`COMMERCIAL-LICENCE.md`](COMMERCIAL-LICENCE.md).

That is the only case. See the table there before assuming you are in it.

## 5. The name is not in the licence

"Sparkilo" and the Sparkilo logo are trademarks of Florian DITTGEN. The
AGPL gives you the code, never the name — see
[`TRADEMARK.md`](TRADEMARK.md). A fork is welcome; it needs its own name.
