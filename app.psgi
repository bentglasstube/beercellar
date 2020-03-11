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

  my $beer = database->quick_select(beer => { beer_id => $id });

  if ($beer) {
    my $brewery = database->quick_select(brewery => { brewery_id => $beer->{brewery_id} });
    my @bottles = database->quick_select(bottle => { beer_id => $id });

    template 'beer.tt', {
      beer => $beer,
      brewery => $brewery,
      bottles => \@bottles,
    };
  } else {
    send_error('Beer not found', 404);
  }
};

get '/beer/:id/edit' => sub {
  my $id = route_parameters->get('id');

  my $beer = database->quick_select('beer', { beer_id => $id });
  my $brewery = database->quick_select('brewery', { brewery_id => $beer->{brewery_id} });

  template 'beer-form.tt', {
    beer => $beer,
    brewery => $brewery,
    verb => 'Edit',
  };
};

post '/beer/:id/edit' => sub {
  my $id = route_parameters->get('id');

  my $brewery_id = body_parameters->get('brewery_id');

  unless ($brewery_id) {
    my $name = body_parameters->get('brewery');
    database->quick_insert('brewery', { name => $name });
    $brewery_id = database->quick_lookup(brewery => { name => $name }, 'brewery_id');
  }

  database->quick_update(
    'beer', { beer_id => $id },
    {
      name => body_parameters->get('name'),
      year => body_parameters->get('year'),
      brewery_id => $brewery_id,
      style => body_parameters->get('style'),
      abv => body_parameters->get('abv'),
    }
  );

  redirect "/beer/$id";
};

del '/bottle/:id' => sub {
  my $id = route_parameters->get('id');

  # TODO authorization
  database->quick_delete('bottle', { bottle_id => $id });
  send_error('', 204);
};

get '/beer' => sub {
  template 'beer-form.tt', { verb => 'Add' };
};

dance;
