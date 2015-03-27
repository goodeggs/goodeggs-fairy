fibrous = require 'fibrous'
Github = require 'goodeggs-fairy/app-services/github'
emailer = require 'goodeggs-emailer'
util = require 'util'
{HttpError} = require 'github'

fileHasModelBuilder = (repo, blacklist=/(?!x)x/) ->
  cache = {}
  fibrous (filename, ref) ->
    console.log "fileHasModel checking #{filename} @ #{ref}"
    key = "#{filename}@#{ref}"
    if (state = cache[key])?
      # we're done
    else if blacklist.test(filename)
      state = cache[key] = false
    else
      file = repo.sync.getFile filename, {ref}
      state = cache[key] = !!file.content().match(/mongoose[.]model/)
    console.log "fileHasModel #{filename} #{ref} #{state and 'is' or 'is not'} model"
    return state

module.exports = (bot, repo, payload) ->
  repo = new Github(bot).repo(owner: repo.owner, name: repo.name)
  trace = (args...) ->
    bot.trace "data-model-changes #{repo.owner}/#{repo.name}: #{util.format args...}"
  emailer.configure
    settings:
      mailerUsername: process.env.MAILER_USERNAME
      mailerPassword: process.env.MAILER_PASSWORD
      appInstance: process.env.APP_INSTANCE or 'localhost'
      mailerWhitelist: ['bob@goodeggs.com', 'aaron@goodeggs.com']
      mailerIgnoreWhitelist: process.env.MAILER_IGNORE_WHITELIST in ['true', '1']
      logger: error: trace, info: trace
  emailer.connect()
  FILE_BLACKLIST = /^src\/orzo/

  return unless payload.ref is 'refs/heads/master'

  fibrous.run ->
    trace 'starting'

    modelChanges = []
    fileHasModel = fileHasModelBuilder repo, FILE_BLACKLIST
    {after, before, commits} = payload

    for commit in commits
      trace "commit #{commit.id}"
      filenames = _.union(commit.added, commit.removed, commit.modified) 
      for filename in filenames when fileHasModel.sync(filename, before) or fileHasModel.sync(filename, after)
        trace "file #{filename} is a model"
        fullCommit = repo.sync.getCommit commit.id
        {patch} = _.find fullCommit.files, (file) -> file.filename is filename
        modelChanges.push {filename, sha: commit.id, url: fullCommit.html_url, patch, author: commit.author}

    return unless modelChanges.length

    modelChangesByRecipient = _.groupBy modelChanges, ({author}) -> "#{author.name} <#{author.email}>"

    for recipient, modelChanges of modelChangesByRecipient
      emailer.sync.send buildEmail({recipient, repo, payload, modelChanges})

  , (err) ->
    if err?
      if typeof err is 'string'
        console.error new Error(err)
      else
        console.error(err.stack or err)
    emailer.disconnect()
    trace 'finished'


buildEmail = ({recipient, repo, payload, modelChanges}) ->
  {renderable, p, pre, code, a, h6, text, br, div, strong} = require 'teacup'

  pluralize = (len, singular, plural) ->
    len is 1 and singular or plural

  template = renderable (repo, payload, modelChanges) ->
    p ->
      text 'In a recent '
      a href: payload.compare, 'push'
      text " to #{repo.owner}/#{repo.name}, I detected #{modelChanges.length} #{pluralize modelChanges.length, 'change', 'changes'} to files containing Mongoose models.  Please review the #{pluralize modelChanges.length, 'diff', 'diffs'} below and consider notifying the Data Team (you can reply directly to this email)."

    p ->
      text 'Thanks,'
      br()
      text '--The Good Eggs Fairy'

    for {filename, url, sha, patch} in modelChanges
      div ->
        div ->
          strong ->
            text "#{filename} @ "
            a href: url, sha[0...7]
        pre ->
          code patch

  return {
    to: recipient
    from: 'delivery-eng+fairy@goodeggs.com'
    cc: 'delivery-eng@goodeggs.com'
    replyTo: 'data@goodeggs.com'
    subject: "Data model changes in #{repo.owner}/#{repo.name} ##{payload.after[0...7]}"
    html: template(repo, payload, modelChanges)
  }

