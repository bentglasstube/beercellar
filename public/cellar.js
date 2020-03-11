$(function() {
  if ($('#beers')) {
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
  }

  $('.bottles button').click(function(e) {
    var btn = $(this)
    var id = btn.attr('data-id');
    $.ajax('/bottle/' + id, {
      method: 'DELETE',
      success: function(data, st, xhr) { btn.parent().fadeOut(); },
    });
    e.preventDefault();
  });
});
