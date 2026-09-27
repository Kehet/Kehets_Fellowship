# Kehet's Fellowship

A World of Warcraft addon that remembers the great players you meet in groups. Had a healer who kept everyone alive, or a tank who waited for the slow pull? Give them a good score, and Fellowship tells you when they join your group again.

## How it works

Fellowship remembers every player you group with, in parties and in raids. When a known player joins your group, chat shows a line with their score, note and when you last grouped with them. Players with a positive score are announced as "Good player joined" in green, so you notice them right away.

When you leave a group, a window opens with every player from that group. For each player you can:

- Give a score from -2 to 2. A positive score marks them as a good player.
- Write a note and press Enter to save it.
- Add comma-separated tags and press Enter to save them.

The window adds the role each player had in the group (Tank, Healer or DPS) to their tags, unless they already have that tag.

When a player is removed from your group by a kick vote, Fellowship adds the `Vote-kicked` tag to them and adds the kick reason to their note.

When you mouse over a known player, the tooltip shows their score, note and when you last saw them. Positive scores are green and negative scores are red.

The player list is stored separately for each faction on each realm.

## Minimap button

Left-click the minimap button to open the rating window for your previous group again. Right-click it to open the player list.

## Player list

The player list window shows every known player in a table with their class, score, how many times you grouped, when you last grouped, tags and note.

- Click a column header to sort by that column. Click it again to reverse the order.
- Type in the search box to filter by name, class, tags or note.
- Use the score menu to show only positive, neutral or negative players.
- Use the Previous and Next buttons to move between pages of 25 players.
- Mouse over a row to see the full note and tags.

## Commands

Use `/fellow` or `/fellowship`. Player names use the format `name-realm`.

| Command | Action |
|---|---|
| `/fellow list` | Open the player list window |
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
