#!/usr/bin/env perl

use Dancer2;
use Dancer2::Plugin::Database;

get '/' => sub {
  my ($req) = shift;

  my $sth = database->prepare(q{
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
    group by beer.beer_id
  });
  $sth->execute();

  template 'cellar.tt', {
    beers => $sth->fetchall_arrayref({}),
  };
};

get '/beer/:id' => sub {
  my ($req, $id) = shift;

  my $beer = database->prepare(q{
    select beer.*, brewery.name as brewery
    from beer join brewery using (brewery_id)
    where beer_id = ?
  });

  $beer->execute($id);
  my $data = $beer->fetchrow_hashref();
  $beer->finish();

  if ($data) {
    my $bottles = database->prepare('select * from bottle where beer_id = ?');
    $bottles->execute($id);
    $bottles->finish();

    template 'beer.tt', {
      beer => $data,
      bottles => $bottles->fetchall_arrayref({}),
    };
  } else {
    send_error('Beer not found', 404);
  }
};

dance;
