# Changelog

Each release's notes come from its section here (the release workflow requires one).

## 0.12.4

Fixes from a full code review.

**Dia ✦**
- 🩹 The shortcut recorder no longer swallows every key once you click away from Settings, and accepts F2–F12; shortcuts need ⌃ or ⌘ (⌥+digit types characters on many layouts, so the ⌥1…⌥9 profile option is gone).
- 🩹 Fixed a possible crash when windows close, and when a stray character is pasted into the command bar.
- 🔐 DayPatch no longer overwrites Dia's own settings: page-content extraction and telemetry sampling are only changed while *Hide AI* / *Block telemetry* are on, and Dia's values come back when they're off. Values earlier versions wrote are cleared once.
- ⌨️ Command bar: Backspace removes an autocompletion; Enter never acts on results from an earlier keystroke; bookmarklets, `data:` and `view-source:` URLs open as themselves; plain text searches with your search engine; new bookmarks and search-engine changes show up without restarting; the active profile's history is used; accented searches match any case.
- 🧭 Typed addresses: LAN addresses (`192.168.x.x`, `*.local`, `[::1]`) open over http, schemes are matched in any case.
- 🗂️ Sorting and grouping tabs never moves pinned tabs or tabs from another profile; `example.com.` groups with `example.com`.
- ⌨️ ⌘T, ⌘L and ⌃⌘U work with Caps Lock on.
- 🛡️ Safer against Dia updates: hooks install all-or-nothing instead of half-way.

**DayPatch**
- 🩹 Never replaces Dia while it (or the original Dia during a passkey handoff) is running or has just updated itself; an interrupted swap is recovered instead of leaving Dia missing.
- 🩹 A failed self-update puts the old DayPatch back; the background job and login item follow DayPatch when it's moved.
- 🩹 A failing automatic patch waits for you instead of retrying every 2 minutes; the window no longer freezes while checking Dia's signature.
- 🩹 The background job notices Dia starting and quitting; switching to a separate copy works before Dia was ever patched; the old profile merge runs only once.
- 🔢 Pre-release versions (`1.3.0-beta`) compare correctly and are published as pre-releases.

## 0.12.3

- 🫥 With the URL bar in the sidebar, Dia's top bar stays hidden while the sidebar is collapsed (e.g. in focus mode) instead of popping back each time the sidebar slides away.
- 🩹 The sidebar URL bar is added right away at launch, even while the sidebar is still hidden.

## 0.12.2

- 🩹 The sidebar URL bar and ← → ↻ buttons appear when Dia ✦ starts, not only after switching with ⌃⌘U.

## 0.12.1

- 🔐 DayPatch is signed with the hardened runtime, so other programs can't inject code into it through `DYLD_INSERT_LIBRARIES` and use its App Management permission.
- 🛡️ DayPatch re-patches Dia ✦ when its signature no longer verifies (for example a swapped `daypatch.dylib`), and only patches or restores a Dia signed by The Browser Company.
- 🔑 Updates come from this fork (`ejthbit/daypatch`), signed with its own key.
- 🩹 Relaunching after an update no longer builds a shell command from the app's path.

## 0.12.0

- ⌨️ **Extra shortcuts** (Settings › DayPatch › Shortcuts, off by default, each one changeable): sort tabs by domain (⌃⌥S), group tabs by domain (⌃⌥G), next / previous profile (⌃⌥→ / ⌃⌥←), move the current tab to the next profile (⌃⌥⇧→), and switch to profile 1–9 (⌃1…⌃9).
- 📏 The sidebar URL bar is as wide as the pinned tabs below it.
- 🩹 The command bar's tab actions talk to Dia ✦ itself, never the original Dia while a passkey handoff has it open.
- 🩹 Fixed a possible crash at launch when Dia's scripting support isn't ready yet.

## 0.11.1

- 🔐 **Passkeys from Apple Passwords:** Dia ✦ menu › **Use Passkeys in Original Dia…** reopens your tabs in the original Dia so Touch ID passkeys work, with a **Back to Dia ✦** button to return. (Apple only allows them in Dia's own app.)
- 🗂️ **Dia ✦ uses your regular Dia profile again.** Renaming the app had given it a profile of its own, so tabs, history and logins drifted apart from the original Dia (which Restore and Update Dia… open). DayPatch moves the newer profile back into place once, keeping the older one in `~/Library/Application Support/daypatch/profile-backups`.
- ✦ The star now comes from the display name and the app menu; Dia's internal name stays "Dia".
- 🔗 DayPatch links to its GitHub page (window footer and menu bar menu), and both DayPatch and Dia's Settings pane say it isn't affiliated with The Browser Company.

## 0.11.0

- 🩹 **Dia is patched in place** by default and becomes **Dia ✦**. The original is kept, so **Restore** puts it back in one click.
- 📦 Prefer a separate app? Untick **Patch Dia directly** to get `~/Applications/Dia ✦.app` and leave Dia untouched.
- 🔄 **Dia's own updater stays on** (in place); DayPatch re-patches after an update. **Update Dia…** remains as a fallback.
- 🙈 Hide AI now also hides **Chat with this tab** in tab hover cards.
- 🫥 **Reveal top bar on hover** is now off by default.
- 🔎 Command bar: most-visited sites rank first (`g` → Google), and result text has more contrast in dark mode.
- 🎛️ Settings pane: content no longer scrolls under the title bar.
- 🧹 The old `Patched Dia.app` is moved to the Trash once Dia ✦ is ready.

## 0.10.1

- 🖼️ README screenshots; "DayPatch" spelled consistently in the UI.

## 0.10.0

- 🎉 First release as DayPatch.
