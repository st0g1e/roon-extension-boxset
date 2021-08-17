#!/usr/bin/perl

use DBI;
use LWP::Simple qw/get/;
use JSON;

my $dbname = "./roonApi/library.sqlite";
my $dbh;

my $topURL = "http://localhost:3002/roonAPI";
my $zone = "";

my $multisessionKey = time();

&connectDB();

&processRoonApiImports();

&disconnectDB();


sub processRoonApiImports {
  print "START process roonApi imports\n";

  if ($zone =~ m/^$/ ) {
    getZone()
  }

  print "-  Process data starting with Artist\n";
  my $apis = &traverseArtistAPI();
  &saveAPIs("roonApis", $apis);

 # FOR VARIOUS ARTISTS SINCE NOT COVERED BY ARTIST TRAVERSAL
  print "-  Process data for starting with Album\n";
  my $albumApis = &traverseAlbumAPI();
  &saveAPIs("roonApis", $albumApis);

  print "-  Process parent/child relationship\n";
  &updateParentChild();

  print "FINISH process roonApi imports\n";
}

sub updateParentChild {
  my $artistId;
  my $albumId;

  my $sth = $dbh->prepare( "select * from roonApis order by id" );
  my $updStr = $dbh->prepare( "update roonApis set parentId = ? where id = ? " );

  $sth->execute();

  while ($row = $sth->fetchrow_hashref()) {
    # ARTIST'S PARENT ALWAYS 0
    if ( $row->{'level'} =~ m/artist/ && $row->{'hint'} =~ m/^list$/ ) {
      $artistId = $row->{'id'};
      undef $albumId;

      $updStr->execute( 0, $row->{'id'} );
    } elsif ( $row->{'level'} =~ m/album/ && $row->{'hint'} =~ m/^list$/ ) {
      $albumId = $row->{'id'};

      $updStr->execute( $artistId, $row->{'id'} );
    } elsif ( $row->{'level'} =~ m/track/ ) {
      $updStr->execute( $albumId, $row->{'id'} );
    }
  }
}

sub traverseArtistAPI {
  my @toReturn;
  my $artists = &listByTitle("Artists", &getLibrary());

  for (my $idx = 0; $idx <= $#{$artists}; $idx++) {
    $artists->[$idx]->{'level'} = "artist";
    push(@{$toReturn}, $artists->[$idx]);

    my $curArtist = &getBySequence($artists->[$idx]{'sequence'});
    my $albums = &listByItemKey($curArtist->{'item_key'}, $curArtist->{'sequence'});

    for (my $aldx = 0; $aldx <= $#{$albums}; $aldx++) {
      $albums->[$aldx]->{'artist'} = $curArtist->{'title'};

      if ( $albums->[$aldx]->{'sequence'} =~ m/^\Q$curArtist->{sequence}|1-0\E/ ) {
          $albums->[$aldx]->{'level'} = "artist";
      } else {
          $albums->[$aldx]->{'level'} = "album";
      }

      push(@{$toReturn}, $albums->[$aldx]);

      my $curAlbum = &getBySequence($albums->[$aldx]{'sequence'});
      my $tracks = &listByItemKey($curAlbum->{'item_key'}, $curAlbum->{'sequence'});

      for (my $trdx = 0; $trdx <= $#{$tracks}; $trdx++) {
        $tracks->[$trdx]->{'artist'} = $curArtist->{'title'};
        $tracks->[$trdx]->{'album'} = $curAlbum->{'title'};

        if ( $albums->[$aldx]->{'sequence'} =~ m/^\Q$curArtist->{sequence}|1-0\E/) {
          $tracks->[$trdx]->{'level'} = "artist";
        } elsif ( $tracks->[$trdx]->{'sequence'} =~ m/^\Q$curAlbum->{sequence}|1-0\E/) {
          $tracks->[$trdx]->{'level'} = "album";
        } else {
          $tracks->[$trdx]->{'level'} = "track";
        }

        push(@{$toReturn}, $tracks->[$trdx]);
      }
    }
  }

  return $toReturn;
}

sub traverseAlbumAPI {
  my @albumReturn;

  my $varArtist;
  $varArtist->{'title'} = "Various Artists";
  $varArtist->{'subtitle'} = "Various Artists";
  $varArtist->{'hint'} = "list";
  $varArtist->{'level'} = "artist";
  $varArtist->{'artist'} = "Various Artists";

  push(@{$albumReturn}, $varArtist);

  my $albums = &listByTitle("Albums", &getLibrary());

  for (my $idx = 0; $idx <= $#{$albums}; $idx++) {
    if ( $albums->[$idx]->{'subtitle'} =~ m/Various Artists/ ) {
      $albums->[$idx]->{'level'} = "album";
      $albums->[$idx]->{'artist'} = $albums->[$idx]->{'subtitle'};
      push(@{$albumReturn}, $albums->[$idx]);

      my $curAlbum = &getBySequence($albums->[$idx]{'sequence'});
      my $tracks = &listByItemKey($curAlbum->{'item_key'}, $curAlbum->{'sequence'});

      for (my $trdx = 0; $trdx <= $#{$tracks}; $trdx++) {
        $tracks->[$trdx]->{'artist'} = $curAlbum->{'subtitle'};
        $tracks->[$trdx]->{'album'} = $curAlbum->{'title'};
        $tracks->[$trdx]->{'level'} = "track";
        push(@{$albumReturn}, $tracks->[$trdx]);
      }
    }
  }

  return $albumReturn;
}

sub saveAPIs {
  my $tableName = $_[0];
  my $apiToSave = $_[1];

  my $sth = $dbh->prepare("insert into " . $tableName . " ( " .
                          "title, subtitle, hint, " .
                          "image_key, sequence, level, " .
                          "artist, album ) " .
                          "values " .
                          "(?, ?, ?, " .
                          "?, ?, ?, " .
                          "?, ? ) ");

  for ( $idx = 0; $idx <= $#{$apiToSave}; $idx++ ) {
    $sth->execute(  $apiToSave->[$idx]->{'title'},
                    $apiToSave->[$idx]->{'subtitle'},
                    $apiToSave->[$idx]->{'hint'},
                    $apiToSave->[$idx]->{'image_key'},
                    $apiToSave->[$idx]->{'sequence'},
                    $apiToSave->[$idx]->{'level'},
                    $apiToSave->[$idx]->{'artist'},
                    $apiToSave->[$idx]->{'album'},
                  );

    if (++$ctr % 5000 == 0) {
      $dbh->commit() or die $dbh->errstr;
    }
  }

  $dbh->commit() or die $dbh->errstr;
}

sub connectDB {
  $dbh = DBI->connect(
      "dbi:SQLite:dbname=$dbname",
      "",
      "",
      { RaiseError => 1,
        AutoCommit => 0
      },
  ) or die $DBI::errstr;
}

sub disconnectDB {
  $dbh->commit() or die $dbh->errstr;
  $dbh->disconnect();
}

sub listByTitle {
  my $title = $_[0];
  my $parentArray = $_[1];

  my $children;

  for ( my $idx = 0; $idx <= $#{$parentArray}; $idx++) {
    if ( $parentArray->[$idx]->{'title'} =~ m/^$title$/ ) {
      $children = &listByItemKey($parentArray->[$idx]->{'item_key'}, $parentArray->[$idx]->{'sequence'});
      break;
    }
  }

  return $children;
}

sub getLibrary {
  my $json = &goHome();
  my $library;

  for (my $idx = 0; $idx <= $#{$json}; $idx++) {
    if ($json->[$idx]->{'title'} =~ m/Library/) {
      $library = $json->[$idx];
      break;
    }
  }

  return &listByItemKey($library->{'item_key'}, $library->{'sequence'})
}

sub goHome {
  my $url = $topURL . "/goHome?&multiSessionKey=" . $multisessionKey . "&zoneId=" . $zone;
  my $content = get $url || die "Couldn't get $url";

  $json = decode_json($content)->{'list'};

  for (my $idx = 0; $idx <= $#{$json}; $idx++) {
    $json->[$idx]->{'sequence'} = "1-$idx";
  }

  return $json;
}

sub getZone {
  my $url = $topURL . "/listZones";
  my $content = get $url || die "Couldn't get $url";

  $json = decode_json($content);

  foreach my $curzone (sort keys %{$json->{zones}}) {
    chomp($curzone);
    $zone = $curzone;
  }
}

sub listByItemKey {
  my $itemKey = $_[0];
  my $sequence = $_[1];

  my $page = 1;
  my $hasMore = 1;

  my $toReturn;

  while ( $hasMore == 1 ) {
    my $returnPage = &listByItemKeyPage( $itemKey, $page, $sequence );

    if ( $returnPage != null && $#{$returnPage} > 0 ) {
      if ( $page == 1 ) {
        $toReturn = $returnPage;
      } else {
        push(@{$toReturn}, @{$returnPage});
      }

      $page++;

      if ( $#{$returnPage} < 99 ) {
        $hasMore = 0;
      }
    } else {
      $hasMore = 0;
    }
  }

  return $toReturn;
}

sub listByItemKeyPage {
  my $itemKey = $_[0];
  my $page = $_[1];
  my $sequence = $_[2];

  my $url = &getUrl(  "listByItemKeyPage?item_key=" . $itemKey .
                      "&start=" . $page);

  my $content = get $url || die "Couldn't get $url";

  $json = JSON->new->decode($content)->{'list'};

  for (my $idx = 0; $idx <= $#{$json}; $idx++) {
    if ($sequence == null || $sequence =~ m/^$/ ) {
        $json->[$idx]->{'sequence'} = "$page-$idx";
    } else {
        $json->[$idx]->{'sequence'} = $sequence . "|$page-$idx";
    }
  }

  return $json;
}

sub getBySequence {
  my $sequence = $_[0];
  my $toReturn;

  my @seqs = split /\|/, $sequence;

  my $curLevel;

  my $isFirst = 1;
  foreach my $curSeq (@seqs) {
    my ($page, $seqno) = split /\-/, $curSeq;

    if ( $isFirst == 1 ) {
      $curLevel = &goHome();
      $isFirst = 0;
    } else {
      $curLevel = listByItemKeyPage($toReturn->{'item_key'}, $page, $toReturn->{'sequence'});
    }

    $toReturn = $curLevel->[$seqno];
  }

    return $toReturn;
}

sub getUrl {
  return $topURL . "/" . $_[0] . "&multiSessionKey=" . $multisessionKey . "&zoneId=" . $zone;
}
