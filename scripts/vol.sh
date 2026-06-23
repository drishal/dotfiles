#!/usr/bin/env bash
#
# Adjust volume/mute on the physical device EasyEffects is currently feeding.
#
# The system default sink is the EasyEffects virtual sink (apps route into it),
# but that virtual sink's own volume never reaches the speakers — EE pushes the
# processed audio to a *physical* output device whose level is what you actually
# hear. EE follows the active output (use-default-output-device=true), so the
# media keys must target that physical device, and follow it as you switch
# between Spark / aux / speakers in pavucontrol.
#
# Resolver (a single pw-dump pass), in order of preference:
#   1. While audio plays, EE links ee_soe_output_level -> <physical sink>; use it.
#   2. While idle EE drops that link, so pick the highest-priority.session
#      physical sink — the device WirePlumber/EE will route to next.
#   3. If neither resolves (EE not running), fall back to the default sink.
#
# wpctl only accepts numeric ids, so the resolver prints the target node id.
#
# Usage: vol.sh <5%+ | 5%- | toggle>

set -euo pipefail

action="${1:?usage: vol.sh <5%+|5%-|toggle>}"

# Print the PipeWire node id of the physical sink EE feeds, or nothing.
target="$(
  pw-dump 2>/dev/null | python3 -c '
import json, sys

try:
    objs = json.load(sys.stdin)
except Exception:
    sys.exit(0)

nodes, links = {}, []
for o in objs:
    t = o.get("type", "")
    props = (o.get("info") or {}).get("props") or {}
    if t.endswith(":Node"):
        nodes[o["id"]] = props
    elif t.endswith(":Link"):
        links.append(props)

def is_phys_sink(props):
    return (props.get("media.class") == "Audio/Sink"
            and "easyeffects" not in props.get("node.name", ""))

# 1. live link from EasyEffects output -> a physical sink
ee_out = {i for i, p in nodes.items() if p.get("node.name") == "ee_soe_output_level"}
for l in links:
    if l.get("link.output.node") in ee_out:
        tgt = l.get("link.input.node")
        if tgt in nodes and is_phys_sink(nodes[tgt]):
            print(tgt); sys.exit(0)

# 2. idle: highest priority.session physical sink
best = max((p.get("priority.session", 0), i)
           for i, p in nodes.items() if is_phys_sink(p)) if any(
           is_phys_sink(p) for p in nodes.values()) else None
if best:
    print(best[1])
' || true
)"

sink="${target:-@DEFAULT_AUDIO_SINK@}"

if [[ "$action" == "toggle" ]]; then
  wpctl set-mute "$sink" toggle
else
  wpctl set-volume -l 1 "$sink" "$action"
fi
