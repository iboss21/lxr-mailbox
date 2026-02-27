# 🐺 LXR Mailbox System

```
██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝
```

**The Land of Wolves 🐺** — Georgian RP | მგლების მიწა - რჩეულთა ადგილი!

> *ისტორია ცოცხლდება აქ! — History Lives Here!*

---

## Description

**lxr-mailbox** is a multi-framework in-game mailbox system for RedM servers. Players can
send and receive letters through mailbox locations, register a personal mailbox with a unique
postal code, manage a contact list, and purchase replacement letters directly at the post office.

Built to wolves.land / LXR codebase standards with support for **LXR Core**, **RSG Core**,
and **VORP Core** via an auto-detecting framework adapter layer.

---

## Features

- 📬 **Register & manage mailboxes** — unique postal codes for every character
- ✉️ **Send & receive letters** — with subject, message body, and sender name
- 📖 **Mark messages as read/unread** — track your inbox state
- 🗂️ **Contact list** — save, name, and search trusted postal codes for quick sending
- ↩️ **One-click reply** — pre-fills recipient from the inbox
- 🗺️ **Customizable locations** — blips on the map for each mailbox
- 🐦 **Optional pigeon animation** — send a pigeon when mailing
- 💌 **Letter durability system** — letters wear out over multiple uses
- 🛒 **Buy letters at mailboxes** — purchase replacement letters in-game
- 🔔 **Unread mail reminders** — periodic notifications for unread mail
- 🏗️ **Multi-framework** — LXR Core (primary), RSG Core, VORP Core

---

## Framework Support

| Framework | Status |
|-----------|--------|
| LXR Core (`lxr-core`) | ✅ Primary |
| RSG Core (`rsg-core`) | ✅ Primary |
| VORP Core (`vorp_core`) | ✅ Supported |

Framework is auto-detected at runtime (LXR → RSG → VORP priority order).
Override by setting `Config.Framework = 'vorp_core'` (or any framework key) in `config.lua`.

---

## Dependencies

| Dependency | Link |
|------------|------|
| `oxmysql` | https://github.com/overextended/oxmysql |
| `feather-menu` | https://github.com/feather-framework/feather-menu |
| `bcc-utils` | https://github.com/BryceCanyonCounty/bcc-utils |

> **VORP only:** `vorp_core`, `vorp_inventory`, `vorp_character` must be running when using VORP framework.

---

## Installation

1. Place the `lxr-mailbox` folder in your server's `resources` directory.
2. Add `ensure lxr-mailbox` to your `server.cfg`.
3. Ensure all dependencies are running.
4. Customize settings by editing `config.lua`.
5. Database tables are created automatically on first start.
6. Restart the server.

> ⚠️ **Important:** The resource folder **must** be named `lxr-mailbox` exactly. A runtime check will error if the name is wrong.

---

## Configuration

Edit `config.lua` to customize your server. Key settings:

```lua
Config.Framework = 'auto'          -- 'auto', 'lxr-core', 'rsg-core', 'vorp_core'
Config.RegistrationFee = 20        -- Cost to register a mailbox
Config.SendMessageFee = 5          -- Cost per message sent
Config.MailboxItem = "letter"      -- Item name used to open mailbox
Config.LetterPurchaseCost = 10     -- Cost to buy a letter at a mailbox
Config.SendPigeon = false          -- Enable pigeon animation
Config.Notify = "feather-menu"     -- "feather-menu" or "vorp-core"
```

---

## Usage

- **Open Mailbox**: Hold the interact prompt near a mailbox location, or use the `letter` item.
- **Register**: First-time players register their mailbox and receive a unique postal code.
- **Send Mail**: Compose a letter to any postal code.
- **Check Mail**: Browse received letters in the inbox.
- **Contacts**: Add contacts by postal code and give them nicknames for quick sending.

---

## Developer API

Other resources can send mail programmatically via the exported API:

```lua
local MailboxAPI = exports['lxr-mailbox']:getMailboxAPI()

-- Send to a mailbox by ID
local ok, result = MailboxAPI:SendMailToMailbox(mailboxId, subject, message, {
    fromName = "Postmaster",
    fromChar = "SYSTEM",
})

-- Send to a character by identifier
local ok, result = MailboxAPI:SendMailToCharacter(charIdentifier, subject, message, {
    fromName = "Sheriff's Office",
})
```

---

## Server

> **The Land of Wolves 🐺**
> Georgian RP 🇬🇪 | Serious Hardcore Roleplay | Discord & Whitelisted

| | |
|---|---|
| 🌐 Website | https://www.wolves.land |
| 💬 Discord | https://discord.gg/CrKcWdfd3A |
| 🛒 Store | https://theluxempire.tebex.io |
| 👨‍💻 GitHub | https://github.com/iBoss21 |

---

© 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
