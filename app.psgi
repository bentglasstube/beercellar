#!/usr/bin/env perl

use Dancer2;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:data.db', '', '', { sqlite_unicode => 1 })
  or die "Cannot connect to databse";

get '/' => sub {
  my ($req) = shift;

  my $beers = $dbh->prepare_cached(q{
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
    order by beer.name
  });
  $beers->execute();

  template 'cellar.tt', {
    beers => $beers->fetchall_arrayref({}),
  });
};

get '/beer/:id' => sub {
  my ($req, $id) = shift;

  my $beer = $dbh->prepare_cached(q{
    select beer.*, brewery.name as brewery
    from beer join brewery using (brewery_id)
    where beer_id = ?
  });

  $beer->execute($id);
  my $data = $sth->fetchrow_hashref();
  $beer->finish();

  if ($data) {
    my $bottles = $dbh->prepare_cached('select * from bottle where beer_id = ?');
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
