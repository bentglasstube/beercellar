#!/usr/bin/env perl

use v5.24;
use strict;
use warnings;

use DBI;
use JSON::XS;
use Plack::App::File;
use Plack::Builder;
use Plack::Request;

my $dbh = DBI->connect('dbi:SQLite:data.db', '', '', { sqlite_unicode => 1 })
  or die "Cannot connect to databse";

my %handlers = (
  select_single => sub {
    my ($req, $sth) = @_;
    my $data = $sth->fetchall_arrayref({});

    if (@$data) {
      my $resp = $req->new_response(200);
      $resp->content_type('application/json');
      $resp->body(encode_json($data->[0]));
      return $resp;
    } else {
      return $req->new_response(404);
    };
  },

  select_list => sub {
    my ($req, $sth) = @_;
    my $data = $sth->fetchall_arrayref({});

    my $resp = $req->new_response(200);
    $resp->content_type('application/json');
    $resp->body(encode_json($data));
    return $resp;
  },

  nonselect => sub {
    my ($req, $sth) = @_;
    return $req->new_response(204);
  },
);

sub query_app {
  my ($query, $args, $handler) = @_;

  my $sth = $dbh->prepare($query);
  return sub {
    my $req = Plack::Request->new(shift);

    if ($req->path =~ /^\/(\w+)/) {
      $req->parameters->set('id', $1);
    }

    my @bindings = map { $req->parameters->get($_) } @$args;

    if ($sth->execute(@bindings)) {
      my $resp = $handler->($req, $sth);
      $sth->finish();
      return $resp->finalize;
    } else {
      my $resp = $req->new_response(400);
      $resp->content_type('text/plain');
      $resp->body($sth->err);
      return $resp->finalize;
    }
  };
}

builder {
  mount '/api/beers' => query_app(q{
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
  }, [], $handlers{select_list});

  mount '/' => Plack::App::File->new()->to_app;
};
