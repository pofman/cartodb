const webpack = require('webpack');
const UglifyJsPlugin = webpack.optimize.UglifyJsPlugin;
const path = require('path');
const env = require('yargs').argv.env;

const libraryName = 'CartoNode';
const fileName = 'carto-node';

const uglifySettings = {
  test: /\.js(\.babel)?$/,
  sourceMap: true,
  beautify: false,
  mangle: {
    screw_ie8: true,
    keep_fnames: true
  },
  compress: {
    screw_ie8: true
  },
  comments: false,
  output: {
    ascii_only: true
  },
  uglifyOptions: {
    compress: true
  }
};

let plugins = [];

const outputFile = env !== 'build'
  ? fileName + '.js'
  : (plugins.push(new UglifyJsPlugin(uglifySettings)),
    fileName + '.min.js');

const config = {
  entry: './lib/assets/core/javascripts/carto-node/index.js.babel',

  output: {
    path: path.resolve(__dirname, '../../vendor/assets/javascripts/carto-node'),
    filename: outputFile,
    library: libraryName,
    libraryTarget: 'umd'
  },

  devtool: 'source-map',

  module: {
    rules: [{
      test: /\.js(\.babel)?$/,
      loader: 'babel-loader',
      include: [
        path.resolve(__dirname, '../../lib/assets/core/javascripts/carto-node')
      ],
      options: {
        presets: ['es2015'],
        plugins: ['transform-object-assign']
      }
    }]
  },

  plugins: plugins
};

module.exports = config;
