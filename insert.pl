#!/usr/bin/env perl

use v5.24;
use strict;
use warnings;

use DBI;

my $dbh = DBI->connect('dbi:SQLite:data.db', '', '')
  or die 'Cannot connect to database';

sub add_brewery {
  my ($name) = @_;

  my $get = $dbh->prepare_cached('select brewery_id from brewery where name = ?');
  $get->execute($name);
  my ($id) = $get->fetchrow_array();
  $get->finish();

  return $id if $id;

  say STDERR "Adding new brewery $name";
  my $ins = $dbh->prepare_cached('insert into brewery (name) values (?)');
  $ins->execute($name);
  $ins->finish();
  return $dbh->last_insert_id;
}

sub add_beer {
  my ($name, $year, $brewery, $style, $abv) = @_;

  my $brewery_id = add_brewery($brewery);

  my $ins = $dbh->prepare_cached(
    q{
    insert into beer (name, year, brewery_id, style, abv)
    values (?, ?, ?, ?, ?)
    }
  );
  $ins->execute($name, $year, $brewery_id, $style, $abv);
  $ins->finish();

  return $dbh->last_insert_id;
}

sub add_bottle {
  my ($beer_id, $size, $location) = @_;

  my $ins = $dbh->prepare_cached(
    q{
    insert into bottle (beer_id, size, location)
    values (?, ?, ?)
    }
  );
  $ins->execute($beer_id, $size, $location);
  $ins->finish();
}

my @data = (
  [ "8 Maids a Milking", undef,  "The Bruery", "English Sweet/Milk Stout", "11.3%", [
    [750, 'Shelf 1'],
  ]],
  [ "9 Ladies Dancing", undef,  "The Bruery", "American Strong Ale", "14.1%", [
    [750, 'Shelf 1'],
  ]],
  [ "11 Pipers Piping", undef, "The Bruery", "Scotch Ale", "10.8%", [
    [750, 'Shelf 1'],
    [750, 'Shelf 5'],
    [750, 'Shelf 5'],
  ]],
  [ "12 Drummers Drumming", undef,  "The Bruery", "Belgian Quad", "12.0%", [
    [750 , 'Shelf 1'],
  ]],
  [ "Acier", undef, "The Bruery", "English Old Ale", "16.9%", [
    [750, 'Shelf 4'],
    [750, 'Shelf 5'],
  ]],
  [ "All The Chocolate Cows", undef, "The Bruery", "American Imperial Stout", "14.0%", [
      [473, 'Shelf 8'],
    ]],
  [ "All The Cows", undef,  "The Bruery", "American Imperial Stout", "14.0%", [
      [473, 'Shelf 8'],
      [473, 'Shelf 8'],
    ]],
  [ "Aloha Friday", "2020", "The Bruery", "American Imperial Stout", "19.7%", [
      [750, 'Shelf 3'],
    ]],
  [ "Alpha Hop Society: Barrel-Aged Biscotti", undef, "Sierra Nevada", "American Strong Ale", "9.7%", [
      [750, 'Shelf 1'],
    ]],
  [ "American Anthem", "2018", "The Bruery", "American Strong Ale", "13.6%", [
      [750, 'Shelf 5'],
      [750, 'Shelf 5'],
    ]],
  [ "Annuel", "2019", "Bruery Terreux", "American Wild Ale", "11.6%", [
      [750, 'Shelf 10'],
    ]],
  [ "Anxoreux", undef, "Bruery Terreux", "American Wild Ale", "7.0%", [
      [473, 'Shelf 13'],
      [750, 'Shelf 12'],
    ]],
  [ "Apfelsap", undef, "The Bruery", "American Wheatwine Ale", "15.6%", [
      [750, 'Shelf 4'],
    ]],
  [ "Autumn Maple", undef,  "The Bruery", "Fruit and Field Beer", "10.0%", [
      [750, 'Shelf 4'],
    ]],
  [ "Bakery: Cherry Pie", undef,  "The Bruery", "American Imperial Stout", "10.2%", [
      [473, 'Shelf 7'],
    ]],
  [ "Beauregarde", "2019", "Bruery Terreux", "American Wild Ale", "5.3%", [
      [750, 'Shelf 11'],
    ]],
  [ "Bierbara 5.0",  undef, "The Bruery", "Belgian Quad",  "15.4%", [
      [750, 'Shelf 4'],
      [750, 'Shelf 5'],
    ]],
  [ "Black Robusto", undef, "Drake's",    "Robust Porter", "6.3%", [
      [650, 'Shelf 14'],
    ]],
  [ "Black Tuesday", "2017", "The Bruery", "American Imperial Stout", "19.5%", [
      [750, 'Shelf 2'],
      [750, 'Shelf 2'],
      [750, 'Shelf 2'],
    ]],
  [ "Black Tuesday", "2018", "The Bruery", "American Imperial Stout", "19.5%", [
      [750, 'Shelf 2'],
      [750, 'Shelf 2'],
      [750, 'Shelf 2'],
      [750, 'Shelf 2'],
    ]],
  [ "Black Tuesday - Port Barrel Aged", "2017", "The Bruery", "American Imperial Stout", "17.8%", [
      [750, 'Shelf 2'],
    ]],
  [ "Black Tuesday - Red Wine Barrel Aged", "2019", "The Bruery", "American Imperial Stout",         "18.0%", [
      [750, 'Shelf 2'],
      [750, 'Shelf 2'],
    ]],
  [ "Black Tuesday Blueberry Pancake", undef,      "The Bruery", "American Imperial Stout",         "19.2%", [
      [375, 'Shelf 9'],
      [375, 'Shelf 9'],
    ]],
  [ "Black Tuesday Pistachio Vanilla", undef,      "The Bruery", "American Imperial Stout",         "18.0%", [
      [375, 'Shelf 9'],
    ]],
  [ "Black Tuesday Samoa", undef,  "The Bruery", "American Imperial Stout", "19.2%", [
      [375, 'Shelf 9'],
    ]],
  [ "Black Tuesday Spicy Island", undef, "The Bruery", "American Imperial Stout", "19.2%", [
      [375, 'Shelf 9'],
      [375, 'Shelf 9'],
    ]],
  [ "Brycescotti", undef,  "The Bruery", "American Imperial Porter", "13.3%", [
      [750, 'Shelf 4'],
      [750, 'Shelf 5'],
    ]],
  [ "Café Cocoa", undef,  "The Bruery", "American Imperial Stout",  "9.7%", [
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
    ]],
  [ "Cherry Chocolate Rain", "2019", "The Bruery", "American Imperial Stout", "19.5%", [
      [750, 'Shelf 5'],
    ]],
  [ "Chocolate Reign", "2019", "The Bruery", "American Imperial Stout", "21.0%", [
      [750, 'Shelf 6'],
      [750, 'Shelf 6'],
    ]],
  [ "Chronology: 6 Wee Heavy",  undef,  "The Bruery", "Scotch Ale", "13.7%", [
      [750, 'Shelf 6'],
    ]],
  [ "Chronology: 12 Wee Heavy", undef,  "The Bruery", "Scotch Ale", "14.1%", [
      [750, 'Shelf 6'],
    ]],
  [ "Chronology: 18 Wee Heavy", undef,  "The Bruery", "Scotch Ale", "14.2%", [
      [750, 'Shelf 6'],
    ]],
  [ "Chronology: 24 Wee Heavy", undef,  "The Bruery", "Scotch Ale", "13.4%", [
      [750, 'Shelf 6'],
    ]],
  [ "Foreign Bodies", undef,   "Bruery Terreux", "American Wild Ale", "8.5%", [
      [750, 'Shelf 11'],
    ]],
  [ "Frucht: Cucumber", undef,   "Bruery Terreux", "Berlinner Weisse", "4.5%", [
      [473, 'Shelf 13'],
      [473, 'Shelf 13'],
      [473, 'Shelf 13'],
      [473, 'Shelf 13'],
    ]],
  [ "Frucht: Grapefruit & Salt", undef, "Bruery Terreux", "Berlinner Weisse", "4.0%", [
      [750, 'Shelf 10'],
    ]],
  [ "Fuzzy Blue Double BBLs Reserve", undef, "Bruery Terreux", "American Wild Ale", "18.0%", [
      [750, 'Shelf 11'],
    ]],
  [ "Graciano", "2018", "Bruery Terreux", "American Wild Ale", "12.2%", [
      [750, 'Shelf 12'],
    ]],
  [ "Grey Monday",     "2019", "The Bruery", "American Imperial Stout", "19.9%", [
      [750, 'Shelf 6'],
      [750, 'Shelf 6'],
    ]],
  [ "Hoarders Cuvée", "2017", "The Bruery", "American Imperial Stout", "15.2%", [
      [750, 'Shelf 11'],
    ]],
  [ "Hoarders Cuvée", "2017", "Bruery Terreux", "American Wild Ale", "8.2%", [
      [750, 'Shelf 11'],
    ]],
  [ "Hoarders Cuvée", "2018", "Bruery Terreux", "American Wild Ale", "7.9%", [
      [375, 'Shelf 9'],
    ]],
  [ "Imperial Cabinet Gin", undef,  "Bruery Terreux", "American Wild Ale", "11.2%", [
      [750, 'Shelf 12'],
    ]],
  [ "Island Time", undef,  "The Bruery", "English Sweet/Milk Stout", "8.6%", [
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
    ]],
  [ "LXXV", undef, "Bruery Terreux", "American Wild Ale", "8.2%", [
      [750, 'Shelf 10'],
    ]],
  [ "Mash & Coconut", "2017", "The Bruery", "English Barleywine", "13.0%", [
      [750, 'Shelf 4'],
    ]],
  [ "Mash & French Toast", "2019", "The Bruery", "English Barleywine", "13.4%", [
      [750, 'Shelf 1'],
      [750, 'Shelf 6'],
      [750, 'Shelf 6'],
    ]],
  [ "Mash & Vanilla", undef,  "The Bruery", "English Barleywine", "13.3%", [
      [473, 'Shelf 8'],
      [473, 'Shelf 8'],
    ]],
  [ "Mélange No 1", undef,   "Bruery Terreux", "American Strong Ale", "9.5%", [
      [750, 'Shelf 12'],
    ]],
  [ "Midnight Autumn Maple", undef,  "The Bruery", "Fruit and Field Beer", "10.0%", [
      [750, 'Shelf 4'],
    ]],
  [ "Mocha Wednesday", "2017", "The Bruery", "American Imperial Stout", "19.9%", [
      [750, 'Shelf 3'],
    ]],
  [ "Mocha Wednesday", "2019", "The Bruery", "American Imperial Stout", "19.9%", [
      [750, 'Shelf 3'],
      [750, 'Shelf 3'],
      [750, 'Shelf 3'],
    ]],
  [ "Mr. Sanders", undef, "Bruery Terreux", "Belgian Saison", "9.4%", [
      [750, 'Shelf 11'],
    ]],
  [ "Muffin Stuffin", undef,  "The Bruery", "American Imperial Stout", "11.8%", [
      [473, 'Shelf 8'],
      [473, 'Shelf 8'],
    ]],
  [ "PB & Jelly Thursday", "2018", "The Bruery", "American Imperial Stout", "19.2%", [
      [750, 'Shelf 3'],
    ]],
  [ "Poached Fig", undef, "The Bruery", "English Barleywine", "13.2%", [
      [750, 'Shelf 4'],
    ]],
  [ "Rue Sans", "2020", "Bruery Terreux", "American Wild Ale", "12.5%", [
      [750, 'Shelf 10'],
    ]],
  [ "Rue'd Attitude", undef,  "The Bruery", "American Imperial Porter", "12.6%", [
      [750, 'Shelf 1'],
    ]],
  [ "Ruekeller: Märzen", undef,  "The Bruery", "German Märzen", "6.3%", [
      [473, 'Shelf 8'],
      [473, 'Shelf 8'],
    ]],
  [ "Rueminator", undef, "The Bruery", "German Doppelbock", "10.0%", [
      [750, 'Shelf 4'],
    ]],
  [ "Rueuze Reserve", undef, "Bruery Terreux", "Belgian Gueuze", "6.1%", [
      [750, 'Shelf 11'],
    ]],
  [ "So Happens It's Tuesday", "2019", "The Bruery", "American Imperial Stout", "15.0%", [
      [750, 'Shelf 1'],
      [750, 'Shelf 3'],
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
    ]],
  [ "So Happens It's Tuesday Mole", undef, "The Bruery", "American Imperial Stout", "15.0%", [
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
      [473, 'Shelf 7'],
    ]],
  [ "So Happens It's Tuesday S'mores", undef,    "The Bruery", "American Imperial Stout", "15.0%", [
      [750, 'Shelf 3'],
      [750, 'Shelf 3'],
      [750, 'Shelf 3'],
    ]],
  [ "Sour in the Rye", "2016", "Bruery Terreux", "American Wild Ale", "7.7%", [
      [750, 'Shelf 10'],
    ]],
  [ "Sour in the Rye with Cherry and Raspberry", undef, "Bruery Terreux", "American Wild Ale", "6.6%", [
      [750, 'Shelf 12'],
    ]],
  [ "Spontanaheim", undef,   "Bruery Terreux", "American Wild Ale", "5.8%", [
      [750, 'Shelf 11'],
    ]],
  [ "Sucaba", "2019", "Firestone Walker", "English Barleywine", "11.3%", [
      [355, 'Shelf 9'],
    ]],
  [ "Tell No Tales", undef,  "The Bruery", "American Strong Ale", "12.5%", [
      [750, 'Shelf 4'],
    ]],
  [ "The Orchard Project - Apricots", undef, "Bruery Terreux", "American Wild Ale", "8.3%", [
      [375, 'Shelf 13'],
    ]],
  [ "The Orchard Project - Nectarines", undef,    "Bruery Terreux", "American Wild Ale", "8.7%", [
      [375, 'Shelf 13'],
    ]],
  [ "This is Mrs. Ridiculous", undef,  "Bruery Terreux", "American Wild Ale", "7.1%", [
      [750, 'Shelf 10'],
      [750, 'Shelf 10'],
    ]],
  [ "This Is Ridiculous", undef,   "Bruery Terreux", "Belgian Saison", "8.8%", [
      [750, 'Shelf 10'],
      [750, 'Shelf 10'],
    ]],
  [ "Train to Beersel", undef, "Bruery Terreux", "American Wild Ale", "8.4%", [
      [750, 'Shelf 11'],
    ]],
  [ "Tripel Berry Hand Pie", undef,  "Bruery Terreux", "American Wild Ale", "11.8%", [
      [750, 'Shelf 11'],
    ]],
  [ "Twice Peached", undef,   "Bruery Terreux", "American Wild Ale", "8.0%", [
      [750, 'Shelf 10'],
    ]],
  [ "Vermont Sticky Maple", undef,  "The Bruery", "American Imperial Stout", "11.3%", [
      [473, 'Shelf 8'],
      [473, 'Shelf 8'],
      [473, 'Shelf 8'],
    ]],
  [ "Wee So Heavy", undef, "The Bruery", "Scotch Ale", "13.0%", [
      [750, 'Shelf 1'],
    ]],
  [ "West Wood", undef, "The Bruery", "Belgian Quad", "14.9%", [
      [750, 'Shelf 5'],
    ]],
  [ "White Chocolate Warmer", undef, "The Bruery", "American Wheatwine Ale", "14.0%", [
      [750, 'Shelf 5'],
    ]],
  [ "White Chocolate with Raspberry", undef, "The Bruery", "American Wheatwine Ale", "13.1%", [
      [750, 'Shelf 1'],
    ]],
  [ "Wilco Tnago Foxtrot", undef,   "Lagunitas", "American Brown Ale", "7.9%", [
      [650, 'Shelf 14'],
    ]],
);

foreach my $beer (@data) {
  my ($name, $year, $brewery, $style, $abv, $bottles) = @$beer;
  my $beer_id = add_beer($name, $year, $brewery, $style, $abv);
  foreach my $bottle (@$bottles) {
    add_bottle($beer_id, @$bottle);
  }
}
