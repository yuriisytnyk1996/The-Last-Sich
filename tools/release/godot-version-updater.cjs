// Lets commit-and-tag-version read and bump `config/version` in project.godot,
// so the in-game version always matches package.json and the git tag.
const VERSION_LINE = /^config\/version="([^"]*)"$/m

module.exports.readVersion = (contents) => {
  const match = contents.match(VERSION_LINE)
  if (!match) throw new Error('project.godot has no config/version line')
  return match[1]
}

module.exports.writeVersion = (contents, version) =>
  contents.replace(VERSION_LINE, `config/version="${version}"`)
