# Localization

The game's text can be shown in several languages. It uses Godot's gettext workflow: English text in code and resources is the key, a generated template (`.pot`) lists every string, and each language is a `.po` file translated with a PO editor such as Poedit.

## How it works

1. **English is the source.** Text is written in English where it lives: in `tr("…")` calls in scripts, in resources (`Dialogue.lines`, `Item.title`…) and in node properties (`Npc.display_name`, `Room.map_zone`…). English needs no translation file, and any line without a translation shows in English.
2. **Text goes through `tr()` where it is shown.** Menus, the HUD, cards and the dialogue box pass text through `tr()` before showing it, including text read from resources (`tr(item.title)`). Ids, story flags, save keys and saved values are never translated: the save keeps a zone's English name, and the slot list translates it when it shows it.
3. **The template lists every string.** POT generation reads the files in Project Settings > Localization > Template Generation. Godot's own parsers find `tr()` calls in scripts and Control text in scenes. The **Text Extractor** editor plugin (`addons/text_extractor/`) adds what they can't see: the translatable properties of the game's own classes, in `.tres` files and in resources and nodes inside scenes.
4. **The language is an option.** `LanguageSettings` (autoload) picks the system language on first start when the game has it, English otherwise, and saves the choice in the `[language]` section of `user://settings.cfg`. **Options > Language** changes it.
5. **Menus redraw in the new language.** A language change rebuilds every open `MenuScreen` (`_build()` runs again) and keeps focus on the same row. Text already on screen outside the menus (the boss name, a title card) is translated the next time it is shown.

## Workflow

**Update the translations** after adding or changing text:

1. `pnpm i18n:files` fills the Template Generation list with every scene, every script that calls `tr()` and every resource of a class the Text Extractor reads.
2. In the editor: Project > Project Settings > Localization > Template Generation > **Generate**, saved as `locale/the_last_sich.pot`.
3. Merge the template into each language:
   ```sh
   msgmerge --update --backup=none locale/uk.po locale/the_last_sich.pot
   ```
   New strings arrive empty. Strings whose English changed keep the old translation marked **fuzzy**: Godot ignores a fuzzy entry and shows English until it is reviewed.
4. Translate the empty and fuzzy entries in Poedit (or any PO editor) and save.

**Add a language:**

1. Create its file from the template:
   ```sh
   msginit --no-translator --locale=de --input=locale/the_last_sich.pot --output-file=locale/de.po
   ```
2. Add `locale/de.po` in Project Settings > Localization > Translations.
3. Add its code to `LanguageSettings.LOCALES` and its own name ("Deutsch") to `LanguageSettings.NAMES`.
4. Check that the font has its letters. The default font covers Latin and Cyrillic.

`msgmerge` and `msginit` come with gettext (`brew install gettext`).

## Writing translatable code

| Case | Write |
|---|---|
| Text in a script | `add_button(tr("Leave"), go_back)` |
| Text with values | `tr("Price: %d    You have: %d") % [price, amount]`. Translate the format, not the result |
| Counted text | `tr_n("%d coin", "%d coins", n) % n`, so languages with several plural forms get the right one |
| Text from a resource or node | `tr(item.title)` where it is shown |
| Text in a static function | `TranslationServer.tr("Charm")`: `tr()` needs an object |
| A list of names | Build it in a function (`[tr("Sharp"), tr("Smooth")]`), not in a `const`: constants can't call `tr()` |
| Text that must not be translated | `# NO_TRANSLATE` at the end of the line (debug buttons) |
| A note for translators | `# TRANSLATORS: …` on the line above |

POT generation only finds **literal** strings inside `tr()`, `tr_n()` and `atr()`. `tr(some_variable)` translates at runtime but adds nothing to the template, so the literal must appear in a `tr()` somewhere, or come from a property the Text Extractor reads.

Tip texts keep their `{action}` names in English in every language: `Tip.formatted_text()` translates the text first, then swaps the names for key or button labels.

## Files

| File | Role |
|---|---|
| `autoload/language_settings.gd` | `LanguageSettings`: the languages, the saved choice, `set_locale()` |
| `addons/text_extractor/text_parser.gd` | Reads translatable properties from `.tres` and `.tscn` files for POT generation |
| `addons/text_extractor/plugin.gd` | Registers the parser with the editor |
| `tools/update_pot_files.gd`, `tools/pot_files.sh` | `pnpm i18n:files`: fills the Template Generation list. `-- --check` exits with 1 when it is out of date |
| `locale/` | The template and one `.po` file per language |
| `ui/menus/menu_screen.gd` | Rebuilds a screen when the language changes |

## Translatable properties

`TextParser.PROPERTIES` lists them by class. Subclasses inherit the entries (the Otaman is a `Boss`).

| Class | Properties |
|---|---|
| `Dialogue` | `speaker`, `lines` |
| `DialogueChoice` | `text` |
| `DialogueStep` | `speaker` |
| `QuoteStep` | `text`, `author` |
| `TitleStep` | `title`, `subtitle` |
| `StoryOutcome` | `message` |
| `Tip` | `title`, `text` |
| `Item` | `title`, `description`, `lore` |
| `PlayerSkill` | `title`, `description` |
| `CrtPreset` | `display_name` |
| `Npc`, `Boss` | `display_name` |
| `Room` | `map_zone` |

Control nodes in scenes add `text`, every `*_text` property and `title`, unless the node's Auto Translate mode is Disabled (the HUD's currency counter).

## Extending

**A new class with player-facing text:** add it and its properties to `TextParser.PROPERTIES`, and pass the text through `tr()` where it is shown. A `PackedStringArray` property needs a `PackedStringArray()` default, not `[]`: in the editor a script that isn't `@tool` drops a saved value whose type differs from its default, and the parser would read an empty list.

**A new menu page:** build every row in `_build()` and pass the text through `tr()`. `_build()` runs again when the language changes, so it only touches its own rows: connect signals of the screen itself or of autoloads in `_ready()`, after `super()`, as `TitleScreen` and `VideoOptions` do.

## Known limitations

- Godot generates the template only from the editor (there is no command-line option), so step 2 of the workflow is a click.
- The Ukrainian translation is a first draft. Longer Ukrainian text has only been checked against the menu rows, not every screen (HUD toasts, the inventory hints, the map legend).- Gamepad buttons keep their Xbox names (A, B, LB…) in every language; key names come from the system.
- Text outside the menus that is already on screen does not change until it is shown again.
