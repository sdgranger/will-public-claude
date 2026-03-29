# cmux Browser API Reference

Full reference for `cmux browser` subcommands. The browser is a built-in Chromium-based panel that renders alongside terminal panes.

## Targeting

Most subcommands require a target surface. Pass it positionally or with `--surface`:

```bash
cmux browser surface:2 url
cmux browser --surface surface:2 url
```

## Opening a Browser

```bash
cmux browser open [url]                              # open in current workspace
cmux browser open-split [url]                        # open as a split pane (preferred)
# Returns: OK surface=surface:N pane=pane:N placement=split
```

Always parse the returned surface ID for subsequent commands:

```bash
BROWSER_OUT=$(cmux browser open-split https://example.com)
SURFACE=$(echo "$BROWSER_OUT" | grep -o 'surface:[0-9]*')
```

## Navigation

```bash
cmux browser $SURFACE navigate <url> [--snapshot-after]
cmux browser $SURFACE back [--snapshot-after]
cmux browser $SURFACE forward [--snapshot-after]
cmux browser $SURFACE reload [--snapshot-after]
cmux browser $SURFACE url                            # get current URL
cmux browser $SURFACE focus-webview
cmux browser $SURFACE is-webview-focused
```

## Waiting

Block until a condition is met:

```bash
cmux browser $SURFACE wait --load-state complete --timeout-ms 15000
cmux browser $SURFACE wait --selector "#dashboard" --timeout-ms 10000
cmux browser $SURFACE wait --text "Order confirmed"
cmux browser $SURFACE wait --url-contains "/dashboard"
cmux browser $SURFACE wait --function "window.__appReady === true"
```

## Inspection

### Snapshot (preferred — returns structured text)

```bash
cmux browser $SURFACE snapshot                       # full accessibility tree
cmux browser $SURFACE snapshot --interactive         # only interactive elements
cmux browser $SURFACE snapshot --interactive --compact
cmux browser $SURFACE snapshot --selector "main" --max-depth 5
cmux browser $SURFACE snapshot --cursor
```

### Screenshot

```bash
cmux browser $SURFACE screenshot                     # base64 to stdout
cmux browser $SURFACE screenshot --out /tmp/page.png
cmux browser $SURFACE screenshot --json
```

### Get Page Data

```bash
cmux browser $SURFACE get title
cmux browser $SURFACE get url
cmux browser $SURFACE get text [--selector <css>]
cmux browser $SURFACE get html [--selector <css>]
cmux browser $SURFACE get value [--selector <css>]
cmux browser $SURFACE get attr [--selector <css>] [--attr <name>]
cmux browser $SURFACE get count [--selector <css>]
cmux browser $SURFACE get box [--selector <css>]
cmux browser $SURFACE get styles [--selector <css>] [--property <name>]
```

### Boolean Checks

```bash
cmux browser $SURFACE is visible <selector>
cmux browser $SURFACE is enabled <selector>
cmux browser $SURFACE is checked <selector>
```

### Find Elements

```bash
cmux browser $SURFACE find role <role> [--name <text>] [--exact]
cmux browser $SURFACE find text|label|placeholder|alt|title|testid [--exact] <text>
cmux browser $SURFACE find first|last [--selector <css>]
cmux browser $SURFACE find nth [--index <n>] [--selector <css>]
cmux browser $SURFACE highlight <selector>           # visual debug overlay
```

## DOM Interaction

All mutating actions support `--snapshot-after` for quick verification.

### Click & Mouse

```bash
cmux browser $SURFACE click <selector> [--snapshot-after]
cmux browser $SURFACE dblclick <selector>
cmux browser $SURFACE hover <selector>
cmux browser $SURFACE focus <selector>
cmux browser $SURFACE scroll-into-view <selector>
cmux browser $SURFACE scroll [--selector <css>] [--dx <n>] [--dy <n>] [--snapshot-after]
```

### Input

```bash
cmux browser $SURFACE fill <selector> [--text <text>] [--snapshot-after]  # clear + type
cmux browser $SURFACE fill <selector> --text ""                           # clear field
cmux browser $SURFACE type <selector> <text> [--snapshot-after]           # append
cmux browser $SURFACE press|keydown|keyup <key> [--snapshot-after]
cmux browser $SURFACE select <selector> <value> [--snapshot-after]
cmux browser $SURFACE check|uncheck <selector> [--snapshot-after]
```

## JavaScript

```bash
cmux browser $SURFACE eval <script>
cmux browser $SURFACE eval --script <js>
cmux browser $SURFACE addinitscript <script>         # runs on every navigation
cmux browser $SURFACE addscript <script>             # runs once
cmux browser $SURFACE addstyle <css>                 # inject CSS
```

## Frames & Dialogs

```bash
cmux browser $SURFACE frame <selector>               # switch to iframe
cmux browser $SURFACE frame main                     # back to main

cmux browser $SURFACE dialog accept [text]
cmux browser $SURFACE dialog dismiss [text]
```

## Downloads

```bash
cmux browser $SURFACE download wait [--path <path>] [--timeout-ms <ms>]
```

## Storage & Cookies

```bash
cmux browser $SURFACE cookies get [--name <n>] [--url <u>] [--domain <d>] [--all]
cmux browser $SURFACE cookies set --name <n> --value <v> [--domain <d>] [--path <p>]
cmux browser $SURFACE cookies clear [--name <n>] [--all]

cmux browser $SURFACE storage <local|session> get [--key <k>]
cmux browser $SURFACE storage <local|session> set --key <k> --value <v>
cmux browser $SURFACE storage <local|session> clear

cmux browser $SURFACE state save <path>
cmux browser $SURFACE state load <path>
```

## Tabs

```bash
cmux browser $SURFACE tab list
cmux browser $SURFACE tab new [url]
cmux browser $SURFACE tab switch <index>
cmux browser $SURFACE tab close [index]
```

## Console & Errors

```bash
cmux browser $SURFACE console list
cmux browser $SURFACE console clear
cmux browser $SURFACE errors list
cmux browser $SURFACE errors clear
```

## Advanced

```bash
cmux browser $SURFACE viewport <width> <height>
cmux browser $SURFACE geolocation <lat> <lng>
cmux browser $SURFACE offline <true|false>
cmux browser $SURFACE trace <start|stop> [path]
cmux browser $SURFACE network route <pattern> [--abort] [--body <text>]
cmux browser $SURFACE network unroute <pattern>
cmux browser $SURFACE network requests
cmux browser $SURFACE screencast <start|stop>
cmux browser $SURFACE identify
```

## Typical Workflow

```bash
# 1. Open browser in a split
BROWSER_OUT=$(cmux browser open-split http://localhost:3000/login)
SURFACE=$(echo "$BROWSER_OUT" | grep -o 'surface:[0-9]*')

# 2. Wait for page load
cmux browser $SURFACE wait --load-state complete --timeout-ms 10000

# 3. Inspect the page structure
cmux browser $SURFACE snapshot --interactive --compact

# 4. Fill a form
cmux browser $SURFACE fill "#email" --text "user@example.com"
cmux browser $SURFACE fill "#password" --text "secret"
cmux browser $SURFACE click "button[type='submit']" --snapshot-after

# 5. Verify result
cmux browser $SURFACE wait --text "Welcome"
cmux browser $SURFACE get title
```
