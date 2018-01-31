L.drawLocal ||= {}
_.merge(L.drawLocal, {
  split: {
    toolbar: {
      actions: {
        save: {
          title: 'Save changes',
          text: 'Save'
        },
        cancel: {
          title: 'Cancel splitting, discards all changes',
          text: 'Cancel'
        }
      },
      buttons: {
        cutPolyline: 'Split layer'
      }
    }
  },
  zoom: {
    zoomInTitle: 'Zoom in',
    zoomOutTitle: 'Zoom out'
  }
})
