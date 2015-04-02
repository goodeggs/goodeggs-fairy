async = require 'async'
fibrous = require 'fibrous'

class RepoHelper

  constructor: (@repo) ->
    @fileHasModel = async.memoize @fileHasModel.bind(@)

  fileHasModel: fibrous (filename, ref) ->
    file = @repo.sync.getFile filename, {ref}
    state = !!file.content().match(/mongoose[.]model/)
    return state

module.exports = RepoHelper

