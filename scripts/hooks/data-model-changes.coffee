Github = require 'goodeggs-fairy/app-services/github'

module.exports = (bot, repo, payload) ->
  repo = new Github(bot).repo(owner: repo.owner, name: repo.name)
  trace = (str) ->
    bot.trace "data-model-changes #{repo.owner}/#{repo.name}: #{str}"

  return unless payload.ref is 'refs/heads/fairy-testing'

  fibrous.run ->
    trace 'starting'

    {before, after} = payload
    diff = repo.sync.compareCommits base: before, head: after
    for {filename, patch} in diff.files
      file = repo.sync.getFile filename, ref: after
      if file.content().match /mongoose[.]model/
        trace file.filename
        trace file.patch

