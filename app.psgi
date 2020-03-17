#!/usr/bin/env perl

use Dancer2;
use Dancer2::Plugin::Database;

sub find_or_create_brewery {
  my $name = shift;

  my $id = database->quick_lookup(brewery => { name => $name }, 'brewery_id');

  unless ($id) {
    database->quick_insert('brewery', { name => $name });
    debug("Inserting new brewery $name");
    return database->last_insert_id();
  }

  return $id;
}

sub save_beer {
  my $id = shift;

  my %args = map { $_ => body_parameters->get($_) } qw[name year style abv description];
  $args{brewery_id} = find_or_create_brewery(body_parameters->get('brewery'));

  if (defined $id) {
    database->quick_update('beer', { beer_id => $id }, \%args);
  } else {
    database->quick_insert('beer', \%args);
  }
}

hook before_template_render => sub {
  my $tokens = shift;

  $tokens->{sizes} = {
    375 => 'Bottle',
    473 => 'Pint',
    650 => 'Bomber',
    750 => '750',
  };
};

get '/' => sub {
  my $where = '1';
  my @params = ();

  my $order_by = 'name';
  if (my $sort = query_parameters->get('sort')) {
    if ($sort =~ /^[a-zA-Z]+$/) {
      $order_by = $sort;
    }
  }

  if (query_parameters->get('order') eq 'desc') {
    $order_by .= ' desc';
  } else {
    $order_by .= ' asc';
  }

  my $sth;

  if (my $q = query_parameters->get('q')) {
    my $query = qq{
      select
        beer.beer_id as id,
        fts.name as name,
        beer.year,
        fts.brewery,
        fts.style,
        beer.abv,
        count(bottle.beer_id) as quantity
      from fts
      join beer on fts.rowid = beer.beer_id
      left join bottle using (beer_id)
      where fts = ?
      group by beer.beer_id
      order by $order_by
    };

    $sth = database->prepare($query);
    $sth->execute($q);

    debug "QUERY $query ($q)";

  } else {

    $sth = database->prepare(qq{
      select
        beer.beer_id as id,
        beer.name as name,
        beer.year,
        brewery.name as brewery,
        beer.style,
        beer.abv,
        count(bottle.beer_id) as quantity
      from bottle
      join beer using (beer_id)
      join brewery using (brewery_id)
      group by beer.beer_id
      order by $order_by
    });
    $sth->execute();

  }

  my $beers = $sth->fetchall_arrayref({});
  $sth->finish();

  if (@$beers == 1) {
    my $id = $beers->[0]{id};
    debug "Found single beer:";
    redirect "/beer/$id";
  } else {
    template 'cellar.tt', {
      beers => $beers,
      q => query_parameters->get('q'),
      sort => query_parameters->get('sort') // 'name',
      order => query_parameters->get('order') // 'asc',
    };
  }
};

get '/beer' => sub {
  template 'beer-form.tt', { verb => 'Add' };
};

post '/beer' => sub {
  save_beer();
  redirect '/beer/' . database->last_insert_id();
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

post '/beer/:id' => sub {
  my $id = route_parameters->get('id');

  database->quick_insert('bottle', {
      beer_id => $id,
      size => body_parameters->get('size'),
      location => body_parameters->get('location'),
    });

  redirect "/beer/$id";
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
  save_beer($id);
  redirect "/beer/$id";
};

del '/bottle/:id' => sub {
  my $id = route_parameters->get('id');

  # TODO authorization
  database->quick_delete('bottle', { bottle_id => $id });
  send_error('', 204);
};

dance;
