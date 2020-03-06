function makeBeerRow(beer) {
  var tr = $('<tr>');
  tr.append('<td>' + beer.name + (beer.year ? ' (' + beer.year + ')' : '') + '</td>');
  tr.append('<td>' + beer.brewery + '</td>');
  tr.append('<td>' + beer.style + '</td>');
  tr.append('<td class="r">' + beer.abv.toFixed(1)  + '%</td>');
  tr.append('<td class="r">' + beer.quantity + '</td>');

  return tr;
}

function makeInfoRow(text) {
  return $('<tr class="info"><td colspan="5">' + text + '</td></tr>');
}

function loadBeers() {
  $.get('/api/beers',
      function(data, status, xhr) {
        var body = $('table#beers tbody');

        body.children().empty();
        if (data.length == 0) {
          body.append(makeInfoRow('The cellar is empty'));
        }
        for (var i = 0; i < data.length; ++i) {
          body.append(makeBeerRow(data[i]));
        }
      });
}

$(function() {
  loadBeers();

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
