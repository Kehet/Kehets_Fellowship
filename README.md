# Kehet's Reckoning

A World of Warcraft addon that lets you track, rate and remember the players you group with. If a rogue stole your loot, you get a warning when that player joins your group again.

## How it works

Reckoning remembers every player you group with, in parties and in raids. When you group with a known player again, chat shows when you last saw them, plus their score and note if they have one.

When you leave a group, a window opens with every player from that group. For each player you can:

- Give a score from -2 to 2.
- Write a note and press Enter to save it.
- Add comma-separated tags and press Enter to save them.

When you mouse over a known player, the tooltip shows their score, note and when you last saw them. Positive scores are green and negative scores are red.

The player list is stored separately for each faction on each realm.

## Minimap button

Left-click the minimap button to open the rating window for your previous group again.

## Commands

Use `/rec` or `/reckoning`. Player names use the format `name-realm`.

| Command | Action |
|---|---|
| `/rec show` | List all known players in chat |
| `/rec reopen` | Open the rating window for your previous group again |
| `/rec add <player> <score> [note [tags]]` | Set a score, and optionally a note and comma-separated tags |
| `/rec remove <player>` | Remove a player from the list |
| `/rec reset` | Remove all known players, after a confirmation |
| `/rec toggleicon` | Show or hide the minimap button |
| `/rec test` | Load test data and open the rating window |

## Requirements

- World of Warcraft: Mists of Pandaria Classic
- The [Ace3](https://www.curseforge.com/wow/addons/ace3) addon

## License

MIT. See `LICENSE`.
