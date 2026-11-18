class_name QuoteStep
extends CutsceneStep
## Shows a quote over everything (`QuoteCard`), black fade included: put
## a `FadeStep` to black before it for a quote on a black screen. The step
## lasts as long as the quote.

@export_multiline var text := ""
## Shown under the text. Empty: none.
@export var author := ""
## Seconds fully shown.
@export var hold := 3.0
## Seconds to fade in, and again to fade out.
@export var fade := 0.8


func play(run: CutsceneRun) -> void:
	Events.quote_shown.emit(text, author, hold, fade)
	await run.wait(hold + fade * 2.0)
