CREATE TABLE brewery (
  brewery_id integer primary key autoincrement,
  name text not null unique
);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE beer (
  beer_id integer primary key autoincrement,
  name text not null,
  brewery_id integer not null references brewery (brewery_id),
  style text not null,
  abv float not null
, year integer);
CREATE TABLE bottle (
  bottle_id integer primary key autoincrement,
  beer_id integer references beer (beer_id),
  size integer not null,
  location text not null
);
