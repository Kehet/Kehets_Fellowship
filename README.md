# Kehet's Fellowship

A World of Warcraft addon that remembers the great players you meet in groups. Had a healer who kept everyone alive, or a tank who waited for the slow pull? Give them a good score, and Fellowship tells you when they join your group again.

## How it works

Fellowship remembers every player you group with, in parties and in raids. When a known player joins your group, chat shows a line with their score, note and when you last grouped with them. Players with a positive score are announced as "Good player joined" in green, so you notice them right away.

When you leave a group, a window opens with every player from that group. For each player you can:

- Give a score from -2 to 2. A positive score marks them as a good player.
- Write a note and press Enter to save it.
- Add comma-separated tags and press Enter to save them.

The window adds the role each player had in the group (Tank, Healer or DPS) to their tags, unless they already have that tag.

When you mouse over a known player, the tooltip shows their score, note and when you last saw them. Positive scores are green and negative scores are red.

The player list is stored separately for each faction on each realm.

## Minimap button

Left-click the minimap button to open the rating window for your previous group again.

## Commands

Use `/fellow` or `/fellowship`. Player names use the format `name-realm`.

| Command | Action |
|---|---|
| `/fellow show` | List all known players in chat |
| `/fellow reopen` | Open the rating window for your previous group again |
| `/fellow add <player> <score> [note [tags]]` | Set a score, and optionally a note and comma-separated tags |
| `/fellow remove <player>` | Remove a player from the list |
| `/fellow reset` | Remove all known players, after a confirmation |
| `/fellow toggleicon` | Show or hide the minimap button |
| `/fellow test` | Load test data and open the rating window |

## Requirements

- World of Warcraft: Mists of Pandaria Classic
- The [Ace3](https://www.curseforge.com/wow/addons/ace3) addon

## License

MIT. See `LICENSE`.
