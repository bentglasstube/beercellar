CREATE TABLE brewery (
  brewery_id integer primary key autoincrement,
  name text not null unique
);
CREATE TABLE beer (
  beer_id integer primary key autoincrement,
  name text not null,
  brewery_id integer not null references brewery (brewery_id),
  style text not null,
  abv real not null,
  year integer,
  description text not null
);
CREATE TABLE bottle (
  bottle_id integer primary key autoincrement,
  beer_id integer references beer (beer_id),
  size integer not null,
  location text not null
);
CREATE VIEW search_view (beer_id, name, brewery, style, description) as select beer.beer_id, beer.name, brewery.name, beer.style, beer.description from beer join brewery using (brewery_id)
/* search_view(beer_id,name,brewery,style,description) */;
CREATE VIRTUAL TABLE fts using fts5(name, brewery, style, description, content=search_view, content_rowid=beer_id)
/* fts(name,brewery,style,description) */;
CREATE TABLE IF NOT EXISTS 'fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE TRIGGER beer_ai after insert on beer begin
  insert into fts(rowid, name, brewery, style, description)
  select beer.beer_id, beer.name, brewery.name, beer.style, beer.description
  from beer join brewery using (brewery_id)
  where beer.beer_id = new.beer_id;
end;
CREATE TRIGGER beer_ad after delete on beer begin
  insert into fts(fts, rowid, name, brewery, style, description)
  select 'delete', beer.beer_id, beer.name, brewery.name, beer.style, beer.description
  from beer join brewery using (brewery_id)
  where beer.beer_id = old.beer_id;
end;
CREATE TRIGGER beer_au after update on beer begin
  insert into fts(fts, rowid, name, brewery, style, description)
  select 'delete', beer.beer_id, beer.name, brewery.name, beer.style, beer.description
  from beer join brewery using (brewery_id)
  where beer.beer_id = old.beer_id;
  insert into fts(rowid, name, brewery, style, description)
  select beer.beer_id, beer.name, brewery.name, beer.style, beer.description
  from beer join brewery using (brewery_id)
  where beer.beer_id = new.beer_id;
end;
