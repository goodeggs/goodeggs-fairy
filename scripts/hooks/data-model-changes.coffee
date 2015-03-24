fibrous = require 'fibrous'
Github = require 'goodeggs-fairy/app-services/github'
emailer = require 'goodeggs-emailer'
util = require 'util'

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

  return unless payload.ref is 'refs/heads/fairy-testing'
  return if payload.before is '0000000000000000000000000000000000000000' # no ancestor

  fibrous.run ->
    trace 'starting'

    modelChanges = []
    {before, after} = payload

    diff = repo.sync.compareCommits base: before, head: after

    for {filename, patch} in diff.files when !FILE_BLACKLIST.test(filename)
      file = repo.sync.getFile filename, ref: after
      if file.content().match /mongoose[.]model/
        modelChanges.push {filename, patch}

    return unless modelChanges.length

    emailer.sync.send buildEmail({repo, payload, modelChanges})

  , (err) ->
    console.error(err.stack or err) if err?
    emailer.disconnect()
    trace 'finished'


buildEmail = ({repo, payload, modelChanges}) ->
  {renderable, p, pre, code, a, h6, text, br, div, strong} = require 'teacup'

  pluralize = (len, singular, plural) ->
    len is 1 and singular or plural

  template = renderable (repo, payload, modelChanges) ->
    p ->
      text "In your recent push to #{repo.owner}/#{repo.name} #"
      a href: payload.compare, payload.after[0...7]
      text ", I detected changes to #{modelChanges.length} #{pluralize modelChanges.length, 'file', 'files'} containing Mongoose models.  Please review the #{pluralize modelChanges.length, 'diff', 'diffs'} below and consider notifying the Data Team (you can reply directly to this email)."

    p ->
      text 'Thanks,'
      br()
      text '--The Good Eggs Fairy'

    for {filename, patch} in modelChanges
      div ->
        div ->
          strong filename
        pre ->
          code patch

  return {
    to: "#{payload.head_commit.author.name} <#{payload.head_commit.author.email}>"
    from: 'delivery-eng+fairy@goodeggs.com'
    replyTo: 'data@goodeggs.com'
    subject: "Data model changes in #{repo.owner}/#{repo.name} ##{payload.after[0...7]}"
    html: template(repo, payload, modelChanges)
  }

