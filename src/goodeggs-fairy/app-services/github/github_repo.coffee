fibrous = require 'fibrous'

GithubFileGateway = require './github_file_gateway'

class GithubRepo

  constructor: (@_client, {@owner, @name}) ->
    [@user, @repo] = [@owner, @name] # alias for convienience

  getFile: fibrous (path, {ref}) ->
    raw = @_client.repos.sync.getContent {@user, @repo, path, ref}
    new GithubFileGateway raw

  compareCommits: fibrous ({base, head}) ->
    @_client.repos.sync.compareCommits {@user, @repo, base, head}

module.exports = GithubRepo

