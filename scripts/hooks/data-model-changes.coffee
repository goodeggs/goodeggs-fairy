fibrous = require 'fibrous'
Github = require 'goodeggs-fairy/app-services/github'
CheckPushForDataModelChangesCommand = require 'goodeggs-fairy/app-commands/check_push_for_data_model_changes_command'
emailer = require 'goodeggs-emailer'

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

  fibrous.run ->
    trace 'starting'
    command = new CheckPushForDataModelChangesCommand {repo, payload}
    command.sync.run()
  , (err) ->
    trace(err.stack or err) if err?
    emailer.disconnect()
    trace 'finished'

