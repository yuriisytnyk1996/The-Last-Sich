extends ConsoleCommand
## `skill`: lists skills, learns all of them (like F9) or forgets them,
## and opens the next tier (`PlayerSkills`).

const ACTIONS: PackedStringArray = ["list", "all", "reset", "tier"]


func _init() -> void:
	names = ["skill"]
	summary = "List, learn or forget skills; open the next tier"
	usage = [
		"skill list: every skill, * marks learned",
		"skill all: learn every skill for free and open every tier",
		"skill reset: forget every skill (currency isn't given back)",
		"skill tier: open the next tier",
	]


func run(args: PackedStringArray) -> void:
	var skills := player().skills
	match args[0] if args.size() == 1 else "":
		"list":
			write("Tier %d of %d open." % [skills.max_tier, PlayerSkills.TIER_CAP])
			for skill in skills.all:
				var learned := "*" if skills.has(skill.id) else " "
				write("%s %-12s tier %d, %d" % [learned, skill.id, skill.tier, skill.cost])
		"all":
			skills.unlock_all()
			write("Learned every skill.")
		"reset":
			skills.lock_all()
			write("Forgot every skill.")
		"tier":
			if skills.raise_tier():
				write("Tier %d open." % skills.max_tier)
			else:
				write("Every tier is already open.")
		_:
			show_usage()


func complete(index: int, _args: PackedStringArray) -> PackedStringArray:
	return ACTIONS if index == 0 else PackedStringArray()
