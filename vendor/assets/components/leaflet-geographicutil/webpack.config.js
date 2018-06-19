const ExtractTextPlugin = require("extract-text-webpack-plugin");

module.exports = {
  module: {
    rules: [{
        test: /\.coffee$/,
        use: ['coffee-loader']
      }
    ]
  },
  entry: ['./src/leaflet.geographic_util.coffee'],
  output: {
    path: __dirname + '/dist',
    filename: 'leaflet.geographicutil.js'
  },
  externals: {
    'leaflet': 'L'
  },
  resolve: {
    extensions: ['.coffee', '.js']
  }
}
