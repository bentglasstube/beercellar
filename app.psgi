#!/usr/bin/env perl

use Dancer2;
use Dancer2::Plugin::Database;

hook before_template_render => sub {
  my $tokens = shift;
  $tokens->{q} = query_parameters->get('q');
};

get '/' => sub {

  my $where = '1';
  my @params = ();

  if (my $q = query_parameters->get('q')) {
    $where = 'beer.name like ? or brewery.name like ? or beer.style like ?';
    push @params, ("%$q%") x 3;

    debug "Searching for beers matching $where (@params)";
  }

  my $sth = database->prepare(qq{
    select
      beer.beer_id as id,
      beer.name,
      beer.year,
      brewery.name as brewery,
      beer.style,
      beer.abv,
      count(bottle.beer_id) as quantity
    from bottle
    join beer using (beer_id)
    join brewery using (brewery_id)
    where $where
    group by beer.beer_id
  });
  $sth->execute(@params);

  template 'cellar.tt', {
    beers => $sth->fetchall_arrayref({}),
  };
};

get '/beer/:id' => sub {
  my $id = route_parameters->get('id');

  my $beer = database->prepare(q{
    select beer.*, brewery.name as brewery
    from beer join brewery using (brewery_id)
    where beer_id = ?
  });

  $beer->execute($id);
  my $data = $beer->fetchrow_hashref();
  $beer->finish();

  debug "Looking for beer $id: $data";

  if ($data) {
    my $bottles = database->prepare('select * from bottle where beer_id = ?');
    $bottles->execute($id);

    template 'beer.tt', {
      beer => $data,
      bottles => $bottles->fetchall_arrayref({}),
    };
  } else {
    send_error('Beer not found', 404);
  }
};

del '/bottle/:id' => sub {
  my $id = route_parameters->get('id');

  # TODO authorization
  database->quick_delete('bottle', { bottle_id => $id });
  send_error('', 204);
};

dance;
