$(function() {
  $('#q').keyup(function(e) {
    var filter = $(e.target).val();
    var re = RegExp(filter, 'i');
    console.log('Using filter ' + filter);

    var beers = $('#beers tbody tr');
    for (var i = 0; i < beers.length; ++i) {
      var tr = $(beers[i]);
      if (tr.text().match(re)) {
        tr.show();
      } else {
        tr.hide();
      }
    }

  });

  $('form').submit(function(e) {
    e.preventDefault();
  });
});
