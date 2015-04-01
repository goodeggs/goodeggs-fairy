unless describe?
  {specExec} = require 'goodeggs-spec-helpers/runner'
  specExec (specModule) -> [
    'mocha', '--compilers=coffee:coffee-script/register', '--ui=mocha-fibers', '--ui=mocha-lazy-bdd', '--reporter=spec'
    "--spec=#{specModule.filename}"
  ]
