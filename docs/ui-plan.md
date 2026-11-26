# Scoundrel UI refresh: plan

Keep the existing look (dark wood, blood-red health, gold Optimus Princeps type).
The work is about layout and information, not a new art style.

## What's wrong today

**Game screen**
- The room sits near the top and the weapon and Flee sit at the bottom. On tall phones
  there's a big empty band in the middle and nothing ties the zones together.
- None of the zones are labelled. A new player can't tell which empty slot is the
  weapon and which is the discard pile.
- The deck doesn't say how many cards are left. You can only guess from the stack height.
- A weapon's durability (the highest monster it can still hit) is hidden until you
  tap a monster and the option is greyed out.
- Fixed 90 px top margin, so the HUD can sit under the notch / Dynamic Island.

**Main menu**
- Half the screen between the title and the buttons is empty.
- The high score is only shown after a run ends.

## Game screen layout (top to bottom)

```
 [♥  ██████████ 14 / 20 ██████    ]  (⚙)
  Standard ••                 Best 250

  DECK · 31                    DISCARD
  [deck]                        [pile]

  ROOM
 ┌──────────────────────────────────┐
 │ [card]  [card]  [card]  [card]   │   felt "table" panel
 └──────────────────────────────────┘
        (attack options pop up here)

  WEAPON · slays ≤ 7
  [held weapon + slain stack]   (FLEE)
```

1. **HUD**: health bar with a heart icon inside it, settings cog on the right. Under it a
   small row: difficulty name in its accent colour with pips (left), best score (right).
2. **Piles row**: deck on the left, discard moved up to the top right. Small caps
   headers above both; the deck header shows the remaining card count.
3. **Room**: the four cards sit on a rounded, slightly lit "table" panel with a ROOM
   header, centred in the free space so tall phones don't get a dead band.
4. **Weapon row**: weapon slot bottom left with a header that reads
   "Bare hands", "Weapon · any foe" or "Weapon · slays ≤ N". Empty slot shows a faint sword.
   Flee moves to the bottom right.
5. **Safe area**: top and bottom margins come from the device safe area at runtime.

No game rules change. Headers live beside the pile nodes, never inside them, because
save/load and the animations read the piles' children.

## Main menu

- Subtitle under the title: "A Roguelike Card Game".
- A fanned hand of four cards (one monster of each black suit, a weapon, a potion) that
  gently bobs, filling the empty band.
- "Best 250" under the fan when a high score exists.

## Other screens

- Difficulty select: make sure the Back button isn't cut off on 16:9 screens.

## Out of scope for this pass

New art assets, new fonts, changes to settings / game-over layouts beyond small fixes.
