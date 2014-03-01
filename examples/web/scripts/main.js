require.config({
  paths: {
    'jquery': '/bower_components/jquery/jquery'
  },
  packages: [
    {
      name: 'cs',
      location: '/bower_components/require-cs',
      main: 'cs'
    },
    {
      name: 'coffee-script',
      location: '/bower_components/coffee-script/extras',
      main: 'coffee-script'
    }
  ]
})

define(function(require) {
  require('cs!./demo')
})