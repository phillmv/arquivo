const { environment } = require('@rails/webpacker')
const coffee =  require('./loaders/coffee')

environment.loaders.prepend('coffee', coffee)

// cf https://stackoverflow.com/questions/69394632/webpack-build-failing-with-err-ossl-evp-unsupported/69476335#69476335

environment.config.output.hashFunction = 'sha256'
module.exports = environment
