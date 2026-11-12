tern.css("notop", [[
/* Reclaim the reserved bands around the terminal in the clean layouts. */
html.lay-rail.tabs-v.tabs-auto {
	--tn-band: 0px;
	--vt-room: 0px;
	background: var(--tv-bg);
}
html.lay-rail.tabs-v.tabs-auto #panel { background: var(--tv-bg); }
html.lay-float { --tn-bar: max(28px, calc(32px * var(--tn-zoom, 1))); }

/* Replace the broad working glow with one quiet border on a lone pane.
   It disappears while the pointer is elsewhere and remains on keyboard focus. */
.tn-stage .tn-pane.lone:not(.pip, .glimpse) { border-radius: 12px; }
.tn-stage .tn-pane.lone:not(.pip, .glimpse) > .tn-body {
	border-radius: inherit;
	box-shadow: inset 0 0 0 1px transparent;
	transition: box-shadow 0.18s var(--out);
}
.tn-stage .tn-pane.lone:not(.pip, .glimpse):is(:hover, :focus-within) > .tn-body {
	box-shadow:
		inset 0 0 0 1px var(--l2),
		0 12px 30px -18px rgba(0, 0, 0, 0.65);
}
.tn-stage .tn-pane.lone:not(.pip, .glimpse) :is(.tn-glow, .tn-zoomring) {
	display: none;
}

/* The small side handle follows the same auto-hide behavior. */
.tn-stage .tn-pane.lone:not(.pip, .glimpse) :is(.tn-grip, .tn-hb) {
	opacity: 0;
	transition: opacity 0.18s var(--out);
}
.tn-stage .tn-pane.lone:not(.pip, .glimpse):is(:hover, :focus-within) :is(.tn-grip, .tn-hb),
.tn-stage .tn-pane.lone:not(.pip, .glimpse) :is(.tn-grip, .tn-hb):focus-visible {
	opacity: 1;
}
]])
