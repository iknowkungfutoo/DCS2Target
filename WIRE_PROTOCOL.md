# TMHotasLEDSync Wire Protocol

**This file is a mirror.** The canonical copy lives in [`TMHotasLEDSync`'s `WIRE_PROTOCOL.md`](https://github.com/iknowkungfutoo/TMHotasLEDSync/blob/main/WIRE_PROTOCOL.md) - if you're changing tag assignments, packet grammar, or per-aircraft field lists, edit it there first, then copy the changes here. Keeping both in sync is manual (these are three separate repos with no shared build), so check the canonical copy if this one looks stale.

**Status: implemented in all three repos - here (as v2.0.0), `TMHotasLEDSync` (as v2.0.0), and `BMS2Target` - all uncommitted/unreleased as of this writing.** Until a release is actually cut across all three together, do not deploy this to end users.

This document is the canonical source of truth for the tag-value wire protocol that replaced the old fixed-position `'u'` (update) packet format. It governs three repositories:

- **[TMHotasLEDSync](https://github.com/iknowkungfutoo/TMHotasLEDSync)** - the receiver. Decodes packets and drives LEDs.
- **dcs2target** (this repo) - a sender, for DCS World.
- **[BMS2Target](https://github.com/iknowkungfutoo/BMS2Target)** - a sender, for Falcon BMS.

Any change to tag assignments, packet grammar, or per-aircraft field lists must be made in the canonical copy first, then implemented consistently across all three repos. See "Change process" at the bottom before adding or modifying anything.

## Why this exists

The previous protocol sent every field at a fixed character offset (e.g. `led_states[10]` always meant F/A-18C's `master_caution_status`). If a sender and receiver ever disagreed about field count or order - a new field inserted mid-packet on one side without a matching change on the other - every field after the mismatch silently decoded as the wrong value. This caused real bugs (F/A-18C wing fold/hook data landing on the wrong LEDs).

The tag-value format below makes every field self-describing: a receiver that doesn't recognize a tag can still skip it correctly (because it knows the length) and leave everything else that follows unaffected. Old and new versions on either end of the connection degrade gracefully instead of corrupting each other's data.

## Packet grammar

```
update_packet := 'u' entry*
entry         := tag length value
tag           := single letter, 'A'-'Z' or 'a'-'z' (never a digit - keeps tags and
                  values visually distinct when eyeballing DEBUG output)
length        := single digit '0'-'9' (how many value characters follow)
value         := exactly `length` digit characters '0'-'9'
```

Only fields that actually changed since the last packet are included - this is a delta protocol, not a full snapshot every frame. On the sender side (this repo), that means: a full snapshot is sent naturally on the first frame after `P.init()` resets a module's cached "previous value" fields to `nil`, because every field then reads as "changed" against `nil`. Don't special-case a "send everything" path - it already falls out of the existing per-field diffing pattern.

**Example:** F-16C reports gear nose down and speed brake at 75%, nothing else changed:
```
uN11B3075
```
(`N` `1` `1` = tag N, length 1, value "1" — gear nose on. `B` `3` `075` = tag B, length 3, value "075" — speed brake 75%.)

## Sender rule (applies to every `*_lamps.lua` module in this repo)

Only append a tag+length+value entry for a field when its own per-field diff says it changed (the existing `updated`/`status_changed` pattern already tracks this per field). Never pad a value to a width other than the table below, and never emit a tag for a field that hasn't changed just because some *other* field in the same payload function changed - each entry is independent.

## Version handshake

Separate from the `'u'` update packet - `dcs2target.lua`'s `create_version_payload()` sends one `'v'` packet on connect, so `TMHotasLEDSync` can log which exporter and version it's talking to. Not the tag-value format above (a one-off handshake, not a repeating payload), but the same self-describing principle:

```
version_packet := 'v' exporter_type version_string
exporter_type  := single character identifying which sender this is - 'D' for
                   dcs2target, 'B' for BMS2Target. Reserve a new letter here
                   (documented) before adding another sender.
version_string := remaining bytes - that sender's own bare version number
                   (e.g. "2.0.0"), no descriptive prefix text.
```

`create_version_payload()` sends `tm_target_utils.VERSION.."D"..dcs2target.VERSION_NUMBER` - the `"D"` here is what identifies this repo as the sender. `dcs2target.VERSION` (the full `"DCS2TARGET v2.0.0"` descriptive string) is still used for local logging via `log.write`; only the bare `VERSION_NUMBER` goes out over the wire.

**Example:** dcs2target v2.0.0 connecting sends `vD2.0.0`; `TMHotasLEDSync` prints `Connected to DCS2Target v2.0.0 (TMHotasLEDSync v2.0.0)`.

## Tag scope: per-aircraft, not global

`TMHotasLEDSync`'s `TCPCallback` dispatches by aircraft before any field decoding happens. Because of that, **a tag only needs to be unique within one aircraft's own table below** - it's safe (and expected) for the same letter to mean different things for different aircraft.

Tags for concepts genuinely shared across aircraft (gear lights, speed brake) are kept consistent everywhere as a convenience, not because the protocol requires it - `generic_aircraft_utils.lua`'s speedbrake payload builder is shared across all aircraft modules in this repo for exactly this reason.

## Shared tags (same meaning for every aircraft that uses them)

| Tag | Meaning | Width | Used by |
|---|---|---|---|
| `N` | Gear Nose | 1 | A-10C, A-10C_2, F-16C, FA-18C, JF-17 |
| `L` | Gear Left | 1 | A-10C, A-10C_2, F-16C, FA-18C, JF-17 |
| `R` | Gear Right | 1 | A-10C, A-10C_2, F-16C, FA-18C, JF-17 |
| `B` | Speed Brake Position (%) | 3 | A-10C, A-10C_2, F-16C, FA-18C, JF-17 |
| `H` | Landing Gear Handle | 1 | A-10C, A-10C_2, FA-18C |
| `W` | Gear Warning | 1 | F-16C, JF-17 |
| `C` | Console / Cockpit Light | 1 | A-10C, A-10C_2, FA-18C |
| `M` | Master Caution | 1 | A-10C, A-10C_2, FA-18C |
| `F` | Fire Warning | 1 | A-10C, A-10C_2, JF-17 |
| `K` | Canopy Unlocked | 1 | A-10C, A-10C_2, JF-17 |

## Per-aircraft tags

### F-16C

| Tag | Meaning | Width |
|---|---|---|
| `N` / `L` / `R` | Gear nose / left / right | 1 |
| `B` | Speed brake position | 3 |
| `W` | Gear warning | 1 |
| `Q` | RWR Search | 1 |
| `A` | RWR Activity | 1 |
| `Z` | RWR A-Power | 1 |
| `J` | RWR Alt Low | 1 |
| `E` | RWR Alt | 1 |
| `V` | RWR System Power | 1 |
| `S` | JFS Run | 1 |
| `G` | Main Gen | 1 |
| `T` | Stby Gen | 1 |
| `C` | FLCS Rly | 1 |
| `U` | EPU Run | 1 |

### A-10C / A-10C_2

| Tag | Meaning | Width |
|---|---|---|
| `N` / `L` / `R` | Gear nose / left / right | 1 |
| `B` | Speed brake position | 3 |
| `H` | Landing gear handle | 1 |
| `K` | Canopy unlocked | 1 |
| `C` | Console light | 1 |
| `M` | Master Caution | 1 |
| `S` | Anti-Skid | 1 |
| `I` | Instrument Inverter | 1 |
| `F` | Fire Warning (OR of left engine / APU / right engine) | 1 |

### FA-18C Hornet

| Tag | Meaning | Width |
|---|---|---|
| `N` / `L` / `R` | Gear nose / left / right | 1 |
| `B` | Speed brake position | 3 |
| `H` | Landing gear handle | 1 |
| `C` | Console light | 1 |
| `M` | Master Caution | 1 |
| `P` | APU Ready | 1 |
| `D` | Wing Fold (handle-engaged proxy - read from the handle's own PULL/STOW argument, not a cockpit lamp or LoGetMechInfo(), neither of which exist for this field) | 1 |
| `X` | Launch Bar | 1 |
| `O` | Arresting Hook | 1 |

### JF-17

| Tag | Meaning | Width |
|---|---|---|
| `N` / `L` / `R` | Gear nose / left / right | 1 |
| `B` | Speed brake position | 3 |
| `W` | Gear warning | 1 |
| `T` | Gear transit | 1 |
| `G` | Master Warning | 1 |
| `F` | Fire Warning | 1 |
| `U` | Fuel Low | 1 |
| `Y` | Hydraulic Caution | 1 |
| `K` | Canopy unlocked | 1 |

## Change process

1. **Adding a field to an existing aircraft:** pick any tag letter not already used *within that aircraft's own table* above (cross-aircraft reuse is fine). Add the row in the canonical copy first, then implement the sender side (the relevant `*_lamps.lua` module here) and the receiver side (the relevant `*_led_utils.tmh` decode branch in `TMHotasLEDSync`) to match.
2. **Never reuse a retired tag's letter for a new meaning within the same aircraft**, even after removing the old field - old packet captures, logs, or not-yet-updated builds in the wild could still be using the old meaning. Retire it (mark unused) instead of reassigning it.
3. **Adding a new aircraft:** create a new per-aircraft table in the canonical copy, free to reuse any letter from other aircraft's tables (tags are aircraft-scoped, not global) except the shared tags, which must keep their shared meaning if the new aircraft has that concept.
4. **Migration:** clean break, decided. `TMHotasLEDSync` does not support both the old fixed-position format and this one - all three repos cut over together. No dual-protocol transition period.
