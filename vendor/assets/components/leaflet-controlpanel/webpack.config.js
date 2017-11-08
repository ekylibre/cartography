const ExtractTextPlugin = require("extract-text-webpack-plugin");

module.exports = {
  module: {
    rules: [{
        test: /\.coffee$/,
        use: ['coffee-loader']
      },
      {
        test: /\.scss$/,
        use: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          //resolve-url-loader may be chained before sass-loader if necessary
          use: ['css-loader', 'sass-loader']
        })
      }
    ]
  },
  entry: ['./src/leaflet.controlpanel.coffee', './src/leaflet.controlpanel.scss'],
  output: {
    path: __dirname + '/dist',
    filename: 'leaflet.controlpanel.js'
  },
  externals: {
    'leaflet': 'L',
    'lodash': '_'
  },
  resolve: {
    extensions: ['.coffee', '.js']
  },
  plugins: [
    new ExtractTextPlugin('leaflet.controlpanel.css')
  ]
}
