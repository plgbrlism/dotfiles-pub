# Rofi Widget Documentation

> A comprehensive guide to Rofi's widget system and styling properties

---

##  Table of Contents

1. [Universal Widget Properties](#0-universal-widget-properties)
2. [Root Window Configuration](#1-root-window)
3. [Overlay](#2-overlay)
4. [MainBox](#3-mainbox)
5. [InputBar](#4-inputbar)
6. [Message](#5-message)
7. [ListView](#6-listview)
8. [Mode-Switcher](#7-mode-switcher)
9. [Widget States](#8-widget-states)

---

## 0. Universal Widget Properties

These properties can be applied to **any** widget in Rofi.

| Property | Type | Description |
|----------|------|-------------|
| `enabled` | boolean | Enable/disable the widget |
| `padding` | length | Internal spacing |
| `margin` | length | External spacing |
| `border` | length | Border thickness |
| `border-radius` | length | Rounded corners |
| `border-color` | color | Border color |
| `border-aa` | boolean | Anti-aliasing for borders |
| `border-disable-nvidia-workaround` | boolean | Workaround for NVIDIA drivers |
| `background-color` | color | Background color |
| `background-image` | path | Background image |
| `cursor` | string | Cursor type (default, pointer, etc.) |

```css
/* Example */
window {
    enabled: true;
    padding: 0px;
    margin: 0px;
    border: 0px;
    border-radius: 0px;
    background-color: transparent;
    cursor: default;
}
```

---

## 1. Root Window

The top-level parent container.

### Hierarchy
```
window
├── overlay
└── mainbox
```

### Properties

| Property | Values | Default | Description |
|----------|--------|---------|-------------|
| `font` | string | - | Font family and size |
| `transparency` | `"real"`, `"background"`, `"screenshot"`, or path | `"real"` | Transparency method |
| `location` | `center`, `east`, `north`, `west`, `south`, `north east`, `north west`, `south west`, `south east` | `center` | Window position |
| `anchor` | `center`, `east`, `north`, `west`, `south`, etc. | `center` | Anchor point |
| `fullscreen` | boolean | `false` | Fullscreen mode |
| `width` | length | - | Window width |
| `x-offset` | length | `0px` | Horizontal offset |
| `y-offset` | length | `0px` | Vertical offset |

```css
window {
    font: "JetBrainsMono Nerd Font 12";
    transparency: "real";
    location: center;
    anchor: center;
    fullscreen: false;
    width: 400px;
    x-offset: 0px;
    y-offset: 0px;
}
```

---

## 2. Overlay

Child of `window`. Used for temporary messages.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `timeout` | integer | `0` | Time (ms) visible when showing temporary message |

```css
overlay {
    timeout: 0;
}
```

---

## 3. MainBox

Child of `window`. The primary container packing the core widgets.

### Hierarchy
```
mainbox
├── inputbar
├── message
├── listview
└── mode-switcher
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `children` | array | `[ inputbar, message, listview, mode-switcher ]` | Child widgets |
| `orientation` | `vertical`, `horizontal` | `vertical` | Layout direction |
| `spacing` | length | `10px` | Distance between packed elements |

```css
mainbox {
    children: [ inputbar, message, listview, mode-switcher ];
    orientation: vertical;
    spacing: 10px;
}
```

---

## 4. InputBar

Child of `mainbox`. Holds the search entry and related prompts.

### Hierarchy
```
inputbar
├── prompt
├── entry
└── case-indicator
```

### Optional Children
- `num-rows`
- `num-filtered-rows`
- `textbox-current-entry`
- `icon-current-entry`

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `children` | array | `[ prompt, entry, case-indicator ]` | Child widgets |
| `orientation` | `vertical`, `horizontal` | `horizontal` | Layout direction |
| `spacing` | length | `10px` | Distance between children |

---

### 4.1 Prompt (Textbox)

Displays prompt text before the entry field.

> Inherits all Textbox properties (see [Entry](#entry) below)

---

### 4.2 Entry (Textbox)

The main text input field.

#### Textbox Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `content` | string | `""` | Displayed text |
| `font` | inherit | `inherit` | Font configuration |
| `text-color` | color | `inherit` | Text color |
| `vertical-align` | float | `0.5` | `0` (top) to `1` (bottom) |
| `horizontal-align` | float | `0.0` | `0` (left) to `1` (right) |
| `text-transform` | string | `none` | `bold`, `italic`, `underline`, `strikethrough`, `uppercase`, `lowercase` |
| `width` | length | `100%` | Desired width |
| `tab-stops` | array | `[ ]` | Tab stop positions |

#### Placeholder Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `placeholder` | string | `"search..."` | Placeholder text |
| `placeholder-color` | color | `inherit` | Placeholder color |
| `placeholder-markup` | boolean | `false` | Enable Pango markup in placeholder |
| `markup` | boolean | `false` | Force Pango markup |

#### Cursor Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `blink` | boolean | `true` | Enable cursor blinking |
| `hide-cursor-on-empty` | boolean | `false` | Hide cursor when empty |
| `cursor-width` | length | `2px` | Cursor width |
| `cursor-color` | color | `inherit` | Cursor color |
| `cursor-outline` | boolean | `false` | Enable cursor outline |
| `cursor-outline-width` | float | `0.0` | Outline width |
| `cursor-outline-color` | color | `inherit` | Outline color |

#### Text Outline Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `text-outline` | boolean | `false` | Enable text outline |
| `text-outline-width` | float | `0.0` | Outline width |
| `text-outline-color` | color | `inherit` | Outline color |

```css
entry {
    content: "";
    font: inherit;
    text-color: inherit;
    vertical-align: 0.5;
    horizontal-align: 0.0;
    text-transform: none;
    width: 100%;
    tab-stops: [ ];
    
    placeholder: "search...";
    placeholder-color: inherit;
    placeholder-markup: false;
    markup: false;
    
    blink: true;
    hide-cursor-on-empty: false;
    cursor-width: 2px;
    cursor-color: inherit;
    cursor-outline: false;
    cursor-outline-width: 0.0;
    cursor-outline-color: inherit;
    
    text-outline: false;
    text-outline-width: 0.0;
    text-outline-color: inherit;
}
```

---

### 4.3 Case-Indicator (Textbox)

Shows case sensitivity status.

> Inherits all Textbox properties

---

## 5. Message

Child of `mainbox`. Holds error or script messages.

### Hierarchy
```
message
└── textbox
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `children` | array | `[ textbox ]` | Child widgets |
| `orientation` | `vertical`, `horizontal` | `horizontal` | Layout direction |
| `spacing` | length | `10px` | Distance between children |

### Textbox

The actual text container inside `message`.

> Inherits all Textbox properties

```css
message {
    children: [ textbox ];
    orientation: horizontal;
    spacing: 10px;
}

textbox {
    /* Textbox properties */
}
```

---

## 6. ListView

Child of `mainbox`. The scrolling grid of results.

### Hierarchy
```
listview
├── element (repeated)
│   ├── element-icon
│   ├── element-text
│   └── element-index
└── scrollbar (optional)
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `columns` | integer | `1` | Number of columns |
| `lines` | integer | `6` | Number of rows |
| `fixed-height` | boolean | `true` | Always show `lines` rows even if empty |
| `dynamic` | boolean | `true` | Change size when filtering |
| `scrollbar` | boolean | `false` | Enable/disable scrollbar |
| `scrollbar-width` | length | `5px` | Scrollbar width |
| `cycle` | boolean | `true` | Wrap around selection |
| `spacing` | length | `5px` | Spacing between elements |
| `layout` | `vertical`, `horizontal` | `vertical` | Layout style (`horizontal` = dmenu style) |
| `flow` | `vertical`, `horizontal` | `vertical` | Order elements are laid out |
| `reverse` | boolean | `false` | Reverse ordering |
| `fixed-columns` | boolean | `true` | Keep columns even if few elements |
| `require-input` | boolean | `false` | Hide until user types |

```css
listview {
    columns: 1;
    lines: 6;
    fixed-height: true;
    dynamic: true;
    scrollbar: false;
    scrollbar-width: 5px;
    cycle: true;
    spacing: 5px;
    layout: vertical;
    flow: vertical;
    reverse: false;
    fixed-columns: true;
    require-input: false;
}
```

---

### 6.1 Scrollbar

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `background-color` | color | `transparent` | Scrollbar background |
| `handle-width` | length | `5px` | Handle width |
| `handle-color` | color | `white` | Handle color |
| `border-color` | color | `transparent` | Border color |
| `handle-rounded-corners` | boolean | `true` | Rounded handle corners |

```css
scrollbar {
    background-color: transparent;
    handle-width: 5px;
    handle-color: white;
    border-color: transparent;
    handle-rounded-corners: true;
}
```

---

### 6.2 Element (Box)

Holds individual list entries.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `children` | array | `[ element-icon, element-text ]` | Child widgets |
| `orientation` | `vertical`, `horizontal` | `horizontal` | Layout direction |
| `spacing` | length | `5px` | Distance between children |

```css
element {
    children: [ element-icon, element-text ];
    orientation: horizontal;
    spacing: 5px;
}
```

---

### 6.3 Element Icon (Icon)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `size` | length | `24px` | Icon size |
| `filename` | string | - | Icon file path |
| `action` | string | - | Can act as a button |
| `squared` | boolean | `false` | Force equal width/height |
| `tint` | color | - | Color tint (white = greyscale) |

```css
element-icon {
    size: 24px;
    /* filename: ""; */
    /* action: "kb-accept-entry"; */
    /* squared: false; */
    /* tint: white; */
}
```

---

### 6.4 Element Text (Textbox)

Takes all Textbox properties plus highlight.

| Property | Type | Description |
|----------|------|-------------|
| `highlight` | string | `text-style {color}` |

```css
element-text {
    highlight: bold underline red;
}
```

---

### 6.5 Element Index (Textbox)

Shows the shortcut keybinding number.

> Inherits all Textbox properties

---

## 7. Mode-Switcher

Child of `mainbox`. Holds buttons to switch between modes (drun, run, etc.).

### Hierarchy
```
mode-switcher
└── button (repeated)
```

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `children` | array | `[ button ]` | Child widgets |
| `orientation` | `vertical`, `horizontal` | `horizontal` | Layout direction |
| `spacing` | length | `10px` | Distance between children |

### Button (Textbox)

> Inherits all Textbox properties
> Automatically receives `action` properties for click functionality

```css
mode-switcher {
    children: [ button ];
    orientation: horizontal;
    spacing: 10px;
}

button {
    /* Textbox properties */
}
```

---

## 8. Widget States

Target specific conditions (hovering, selecting, etc.) by appending states to widget names.

### ListView Element States

| State | Description |
|-------|-------------|
| `normal.normal` | Idle state |
| `alternate.normal` | Idle state, uneven row |
| `selected.normal` | Highlighted by user |

### Urgent States
> Usually set by scripts

| State | Description |
|-------|-------------|
| `normal.urgent` | Idle urgent state |
| `alternate.urgent` | Uneven row urgent state |
| `selected.urgent` | Selected urgent state |

### Active States
> Usually set by scripts

| State | Description |
|-------|-------------|
| `normal.active` | Idle active state |
| `alternate.active` | Uneven row active state |
| `selected.active` | Selected active state |

### Button States

| State | Description |
|-------|-------------|
| `selected` | Currently active mode button |

```css
/* Example state styling */
element normal.normal { background-color: #282a36; }
element alternate.normal { background-color: #1e1f2b; }
element selected.normal { background-color: #44475a; }

element normal.urgent { background-color: #ff5555; }
element alternate.urgent { background-color: #ff5555; }
element selected.urgent { background-color: #ff5555; }

element normal.active { background-color: #50fa7b; }
element alternate.active { background-color: #50fa7b; }
element selected.active { background-color: #50fa7b; }

button selected { background-color: #6272a4; }
```

---

## 📝 Quick Reference

### Widget Hierarchy

```
window
├── overlay
└── mainbox
    ├── inputbar
    │   ├── prompt
    │   ├── entry
    │   └── case-indicator
    ├── message
    │   └── textbox
    ├── listview
    │   ├── element
    │   │   ├── element-icon
    │   │   ├── element-text
    │   │   └── element-index
    │   └── scrollbar
    └── mode-switcher
        └── button
```

### Textbox Properties (Reusable)

Used by: `prompt`, `entry`, `case-indicator`, `textbox`, `element-text`, `element-index`, `button`

- `content`, `font`, `text-color`
- `vertical-align`, `horizontal-align`
- `text-transform`, `width`, `tab-stops`
- `placeholder`, `placeholder-color`, `placeholder-markup`
- `markup`
- `blink`, `hide-cursor-on-empty`
- `cursor-width`, `cursor-color`
- `cursor-outline`, `cursor-outline-width`, `cursor-outline-color`
- `text-outline`, `text-outline-width`, `text-outline-color`
- `highlight` (element-text only)

---

> **Note:** This documentation covers Rofi's widget system in detail. For more information, refer to the [official Rofi documentation](https://github.com/davatorium/rofi).
