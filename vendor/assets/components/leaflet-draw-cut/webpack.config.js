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
  entry: ['./src/leaflet.draw.cut.coffee', './src/leaflet.draw.cut.polyline.coffee', './src/util.coffee', './src/leaflet.draw.cut.scss', './src/leaflet.draw.overlapping.drawing.locking.coffee', './src/leaflet.draw.shape.calculation.coffee',  './src/line-split.js'],
  output: {
    path: __dirname + '/dist',
    filename: 'leaflet.draw.cut.js'
  },
  externals: {
    'leaflet': 'L',
    'lodash': '_'
  },
  resolve: {
    extensions: ['.coffee', '.js']
  },
  plugins: [
    new ExtractTextPlugin('leaflet.draw.cut.css')
  ]
}
