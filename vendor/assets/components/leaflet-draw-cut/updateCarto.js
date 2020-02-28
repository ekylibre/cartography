const exec = require('child_process').exec;

class UpdateCarto {
  apply(compiler) {
    compiler.hooks.done.tapAsync('UpdateCarto', (compilation, callback) => {
        callback();
        exec("cp ./dist/leaflet.draw.cut.js ../cartography/vendor/assets/components/leaflet-draw-cut/dist/leaflet.draw.cut.js ")
        console.log('copied')
    });
  }
}

module.exports = UpdateCarto;