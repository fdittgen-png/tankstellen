<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# The commercial licence

Sparkilo is free software under the AGPL-3.0-or-later. This document is
for the one case the AGPL makes awkward: **a for-profit company that
modifies Sparkilo, serves it over a network, and does not want to
publish its modifications.**

## Do you need it?

Almost certainly not.

| You are | You modify Sparkilo | You need |
|---|---|---|
| an association, collective, school, public body or individual | either way | nothing |
| a company, running Sparkilo as it ships | no | nothing |
| a company, self-hosting the Supabase schema as it ships | no | nothing |
| a company, modified, publishing your changes | yes | nothing |
| a company, modified, kept private, used only in-house | yes | nothing |
| **a company, modified, kept private, served to people over a network** | yes | **this licence** |

The AGPL's §13 obligation is triggered by *modifying* and *serving over
a network*. It is not triggered by *using*, not by *charging*, and not
by *running a commercial fleet on it*. A haulage company that runs
Sparkilo as it ships, gives every driver the app and reconciles its fuel
expenses with it owes nothing and never will. Changing a logo, a colour
or a configuration is not modifying the program.

Note what §13 actually reaches on a phone app. Sparkilo is local-first:
installing it on drivers' devices is **conveying** (§§5-6, which oblige
you only if you distribute a modified build), not network interaction.
§13 bites on the part you host — the self-hosted Supabase schema and its
functions — when you have modified it and your drivers reach it over the
network.

Ask before assuming you owe anything — the table above answers most
people with "nothing".

## What it grants

A perpetual, non-exclusive, non-transferable right to use, modify and
self-host Sparkilo without the source-publication obligations of AGPL
§§5, 6 and 13, for one legal entity and the establishments it operates.

It grants no trademark rights (see [`TRADEMARK.md`](TRADEMARK.md)) and
no right to redistribute Sparkilo, modified or not, as a product of your
own.

## What it costs, and how to ask

Write to the address in the repository's GitHub profile, saying who the
entity is, roughly how many vehicles and drivers it manages, and whether
it self-hosts. The price is set per entity and by size; a two-van
business and a national logistics operator will not be quoted the same
thing.

## Why the project is licensed this way

See [ADR 0028](docs/decisions/0028-agpl-with-a-commercial-exception.md).

The short version: what this is meant to prevent is a company taking the
work, improving it privately and competing with the people who gave it
away. The AGPL prevents exactly that and nothing else, and this
document is the door for a company that would rather pay than publish.

A licence that simply forbade commercial use would have been the obvious
move and was rejected on purpose — it is not free software, it would end
the F-Droid listing, and it would exclude the very drivers and
operators Sparkilo is built for. The reasoning is in the ADR.
