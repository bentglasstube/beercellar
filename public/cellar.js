$(function() {
  function resort(key, dir) {
    $('#sort').val(key);
    $('#order').val(dir);
    $('#search').submit();
  }

  $('button[data-sort]').click(function(e) {
    var btn = $(this);
    var sortkey = btn.attr('data-sort');
    var current = $('#sort').val();

    if (current == sortkey) {
      resort(sortkey, $('#order').val() == 'asc' ? 'desc' : 'asc');
    } else {
      resort(sortkey, 'asc');
    }
  });

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
