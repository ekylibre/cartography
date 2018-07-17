const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CleanWebpackPlugin = require('clean-webpack-plugin');

var glob = require("glob");

module.exports = {
  optimization: {
    splitChunks: {
      cacheGroups: {
        styles: {
          name: 'styles',
          test: /\.css$/,
          chunks: 'all',
          enforce: true
        }
      }
  }
  },
  module: {
    rules: [{
        test: /\.coffee$/,
        use: ['coffee-loader']
      },
      {
        test: /\.scss$/,
	use: [
          //'style-loader',
	  MiniCssExtractPlugin.loader,
	  'css-loader',
          'sass-loader',
        ]
      },
      {
        test: /\.mjs$/,
        include: /node_modules/,
        type: "javascript/auto"
      }
    ]
  },
  entry: glob.sync("./src/*"),
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
    new CleanWebpackPlugin(['dist']),
    new MiniCssExtractPlugin({
      filename: 'leaflet.draw.cut.css'
    })
  ]
}
