#!/usr/bin/env perl

use v5.24;
use strict;
use warnings;

use DBI;
use JSON::XS;
use Plack::App::File;
use Plack::Builder;
use Plack::Request;
use Plack::Middleware::REST;

my $dbh = DBI->connect('dbi:SQLite:data.db', '', '', { sqlite_unicode => 1 })
  or die "Cannot connect to databse";

sub query_app {
  my ($query, $args, $post) = @_;

  say STDERR "Making app from $query";

  my $sth = $dbh->prepare($query);
  return sub {
    my $req = Plack::Request->new(shift);

    if ($req->path =~ /^\/(\w+)/) {
      $req->parameters->set('id', $1);
    }

    my @bindings = map { $req->parameters->get($_) } @$args;

    if ($sth->execute(@bindings)) {
      my $resp = $post->($req, $sth);
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

my $results_post = sub {
  my ($req, $sth) = @_;
  my $data = $sth->fetchall_arrayref({});

  if (@$data) {
    my $resp = $req->new_response(200);
    $resp->content_type('application/json');
    $resp->body(encode_json($data));
    return $resp;
  } else {
    return $req->new_response(404);
  }
};


sub rest_app {
  my ($table) = @_;

  return builder {
    enable 'REST',
      get => query_app(
        "select * from $table->{name} where $table->{primary_key} = ?",
        [ 'id' ], $results_post),

      delete => query_app(
        "delete from $table->{name} where $table->{primary_key} = ?",
        ['id'],
        sub {
          my ($req, $sth) = @_;
          return $req->new_response(204);
        }),

      create => query_app(
        "insert into $table->{name} (" .
        join(', ', @{$table->{columns}}) . ") values (" .
        join(', ', ('?') x @{$table->{columns}}) . ")",
        $table->{columns},
        sub {
          my ($req, $sth) = @_;
          return $req->new_response(204);
        }),

      list => query_app(
        "select * from $table->{name}",
        [],
        sub {
          my ($req, $sth) = @_;
          my $data = $sth->fetchall_arrayref({});
          my $resp = $req->new_response(200);
          $resp->content_type('application/json');
          $resp->body(encode_json($data));
          return $resp;
        });
    };
}

builder {
  mount '/crud/beer' => rest_app({
      name => 'beer',
      primary_key => 'beer_id',
      columns => [qw[name year style brewery_id abv]],
    });

  mount '/crud/bottle' => rest_app({
      name => 'bottle',
      primary_key => 'bottle_id',
      columns => [qw[size location]],
    });

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
  }, [], $results_post);

  mount '/' => Plack::App::File->new()->to_app;
};
