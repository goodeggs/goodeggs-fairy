fibrous = require 'fibrous'

GithubFileGateway = require './github_file_gateway'

class GithubRepo

  constructor: (@_client, {@owner, @name}) ->
    [@user, @repo] = [@owner, @name] # alias for convienience

  getFile: fibrous (path) ->
    raw = @_client.repos.sync.getContent {@user, @repo, path}
    new GithubFileGateway raw

module.exports = GithubRepo

