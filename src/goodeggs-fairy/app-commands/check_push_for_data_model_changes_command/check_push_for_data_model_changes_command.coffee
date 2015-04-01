fibrous = require 'fibrous'
emailer = require 'goodeggs-emailer'
util = require 'util'
{HttpError} = require 'github'
Set = require 'set'

FILE_BLACKLIST = /^src\/orzo/

class CheckPushForDataModelChangesCommand

  constructor: ({@repo, @payload}) ->
    # NOOP

  run: fibrous ->

    return unless @payload.ref is 'refs/heads/master'

    modelChanges = []
    fileHasModel = fileHasModelBuilder @repo, FILE_BLACKLIST
    {after, before, commits, pusher} = @payload

    diff = @repo.sync.compareCommits base: before, head: after

    if diff.commits.length >= 250 # https://developer.github.com/v3/repos/commits/#working-with-large-comparisons
      emailer.sync.send buildDiffWarningEmail({diff})

    modelChanges = {}

    for file in diff.files
      modelChanges[file.filename] = file if false \
        or (status in ['removed', 'modified'] and fileHasModel.sync(file.filename, before)) \
        or (status in ['added', 'modified'] and fileHasModel.sync(file.filename, after))

    for commit in commits
      for filename in _.union(commit.added, commit.deleted, commit.modified)
        continue unless modelChange = modelChanges[filename]
        modelChange.authors ?= new Set
        modelChange.authors.add commit.author

    for filename, modelChange of modelChanges
      recipients = modelChange.authors.get().map (author) -> "#{author.name} <#{author.email}>"
      emailer.sync.send buildEmail({@repo, @payload, recipients, modelChange})


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

buildEmail = ({repo, payload, recipients, modelChange}) ->
  {renderable, p, pre, code, a, h6, text, br, div, strong} = require 'teacup'

  pluralize = (len, singular, plural) ->
    len is 1 and singular or plural

  template = renderable ({repo, payload, modelChange}) ->
    p ->
      text 'In a recent '
      a href: payload.compare, 'push'
      text " to #{repo.owner}/#{repo.name}, "
      code modelChange.filename
      text " was #{modelChange.status} and appears to contain Mongoose models.  Please review the diff below and consider notifying the Data Team (you can reply directly to this email)."

    p ->
      text 'Thanks,'
      br()
      text '--The Good Eggs Fairy'

    div ->
      div ->
        strong modelChange.filename
      pre ->
        code modelChange.patch

  return {
    to: "#{payload.pusher.name} <#{payload.pusher.email}>"
    from: 'delivery-eng+fairy@goodeggs.com'
    cc: ['delivery-eng@goodeggs.com'].concat(recipients).join(', ')
    replyTo: 'data@goodeggs.com'
    subject: "Data model changes in #{repo.owner}/#{repo.name} #{modelChange.filename} push #{payload.after[0...7]}"
    html: template({repo, payload, modelChanges})
  }

buildDiffWarningEmail = ({diff}) ->
  return {
    to: 'delivery-eng@goodeggs.com'
    from: 'delivery-eng+fairy@goodeggs.com'
    subject: 'data-model-changes hit diff threshold'
    body: """
      You asked me to warn you when I asked Github for a diff that spanned 250 or more commits, and I just did:
      
      #{diff.html_url}
      
      Relevant docs: https://developer.github.com/v3/repos/commits/#working-with-large-comparisons
      
      Cheers,
      --The Good Eggs Fairy
    """
  }

module.exports = CheckPushForDataModelChangesCommand

