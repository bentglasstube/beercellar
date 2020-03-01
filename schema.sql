create table if not exists brewery (
  brewery_id integer primary key autoincrement,
  name string not null unique
);

create table if not exists beer (
  beer_id integer primary key autoincrement,
  name string not null,
  brewery_id integer not null references brewery (brewery_id),
  style string not null,
  abv float not null
);

create table if not exists bottle (
  bottle_id integer primary key autoincrement,
  beer_id integer references beer (beer_id),
  size integer not null,
  location string not null
);

alter table beer add column year integer;
