#!/usr/bin/perl

use DBI;
use LWP::UserAgent;

my $dbh;
my $dbFile = "roonApi/library.sqlite";


# ------------------------- ROONDB SQLS ------------------------------
my $UPDATE_ROON_DB =  "update roondb " .
                      "set " .
                      "keyString = ?, " .
                      "valueString = ? " .
                      "where idx = ? ";


# ------------------------- ROON API SQLS ------------------------------
my $GET_ROON_APIS =           "select * from roonApis " .
                              "order by id";

my $UPDATE_ROON_APIS_BY_IMAGEKEY =  "update roonApis " .
                                    "set " .
                                    "album = ?, " .
                                    "albumAscii = ?, " .
                                    "titleAscii = ?, " .
                                    "artistsAscii = ?, " .
                                    "subtitleAscii = ? " .
                                    "where " .
                                    "image_key = ? ";

my $UPDATE_ROON_APIS_BY_ID =  "update roonApis " .
                              "set " .
                              "artist = ?, " .
                              "album = ?, " .
                              "albumAscii = ?, " .
                              "titleAscii = ?, " .
                              "artistsAscii = ?, " .
                              "subtitleAscii = ? " .
                              "where " .
                              "id = ? ";

my $REFRESH_ROON_APIS =   "update roonApis " .
                          "set " .
                          "album = NULL, " .
                          "albumAscii = NULL, " .
                          "titleAscii = NULL, " .
                          "artistsAscii = NULL, " .
                          "subtitleAscii = NULL ";

my $GET_ROON_APIS_ALBUM =     "select * from roonApis " .
                              "where level = 'album' " .
                              "AND " .
                              "image_key is not null " .
                              "order by image_key";

my $REMOVEARTIST_ON_ROON_APIS = "update roonApis " .
                                "set " .
                                "artist = NULL " .
                                "where level = 'track'";

my $UPDATE_ROON_APIS_WITH_ROONPERFORMER = "update roonApis " .
                                          "set " .
                                          "path = ?, " .
                                          "artist = ?, " .
                                          "performerId = ? " .
                                          "where " .
                                          "id = ? ";

my $UPDATE_ROON_APIS_WITH_ROONTRACK = "update roonApis " .
                                      "set " .
                                      "path = ?, " .
                                      "trackId = ? " .
                                      "where id = ? ";

my $UPDATE_ROON_APIS_WITH_ROONALBUM = "update roonApis " .
                                      "set " .
                                      "path = ?, " .
                                      "albumId = ?, " .
                                      "artist = ?, " .
                                      "album = ?, " .
                                      "albumYear = ? " .
                                      "where id = ? ";

my $GET_UNMATCHED_ALBUMS =  "select * from roonApis " .
                            "where " .
                            "level = 'album' AND " .
                            "subtitle is not NULL AND " .
                            "albumId is NULL";

my $GET_ROONAPIS_BY_SEQUENCE =  "select * from roonApis " .
                                "where " .
                                "sequence = ?";

my $UPDATE_ROON_APIS_OBJLEVEL = "update roonApis " .
                                "set " .
                                "objLevel = ?, " .
                                "parentId = ? " .
                                "where id = ? ";

my $INSERT_INTO_ROONAPI_BOXSET = "insert into roonApis ( " .
                                 "parentId, title, subtitle, " .
                                 "hint, level, artist, " .
                                 "album, path, objLevel ) " .
                                 "values " .
                                 "(?, ?, ?, " .
                                 "?, ?, ?, " .
                                 "?, ?, ? ) ";

my $GET_ROONAPIS_BY_PATH = "select * from roonApis " .
                           "where " .
                           "path = ? ";


# ------------------------- PERFORMER SQLS  ------------------------------

my $SELECT_MUSICDB_PERSON = "select * from roonDB " .
                            "where " .
                            "valueHex like '%164d7573696344622e4c6f63616c506572666f726d6572%'";

my $GET_SOOLOOS_PERFORMER =   "select * from roonDB " .
                              "WHERE " .
                              "valueHex like '%536f6f6c6f6f732e4d73672e4d657461646174612e506572666f726d6572%'";

my $GET_ROON_PERFORMERS = "select * from RoonPerformer ";

my $INSERT_TO_ROON_PERFORMER = "insert into RoonPerformer (" .
                              	"performerId, name, type, "	.
                              	"year, relationships, biography, " .
                              	"bioAuthor, description, birthPlace, " .
                              	"genres, country, nameAscii, " .
                                "imageUrl, alsoKnownAs, source, " .
                                "altIds " .
                                ") values ( " .
                                "?, ?, ?," .
                                "?, ?, ?," .
                                "?, ?, ?," .
                                "?, ?, ?," .
                                "?, ?, ?, " .
                                "? ) ";

my $INSERT_PERF_ID_ALTERNATE =  "insert into roonPerformerAltIds " .
                                "( performerId, alternateId ) " .
                                " values " .
                                "( ?, ? ) ";

my $GET_ROONPERFORMER_BY_PERFORMERID = "select * from RoonPerformer " .
                                       "where performerId = ?";

my $GET_MAIN_PERFORMERS_FROM_ALBUM =  "select " .
                                      "roonMainPerformers.mapTo, " .
                                      "roonMainPerformers.mapToId, " .
                                      "roonMainPerformers.performerId, " .
                                      "roonPerformer.name, " .
                                      "roonPerformer.nameAscii " .
                                      "from " .
                                      "roonMainPerformers, roonPerformer " .
                                      "where roonMainPerformers.performerId = roonPerformer.performerId AND " .
                                      "roonMainPerformers.mapTo = 'album' AND " .
                                      "roonMainPerformers.mapToId = ? ";

my $GET_PERFORMER_BY_NAMEASCII =  "select * from roonPerformer " .
                                  "WHERE nameAscii = ? " .
                                  "order by type DESC, source, imageUrl DESC ";

# ------------------------- ALBUM SQLS  ------------------------------

my $SELECT_MUSICDB_ALBUM =  "select * from roonDB " .
                            "where " .
                            "valueHex like '%124d7573696344622e4c6f63616c416c62756d%'";

my $GET_SOOLOOS_ALBUM =       "select * from roonDB " .
                              "WHERE " .
                              "valueHex like '%536f6f6c6f6f732e4d73672e4d657461646174612e416c62756d%'";

my $INSERT_TO_SOOLOOSALBUM =  "insert into RoonSooloosAlbum (" .
	                            "year, albumId, reviewText, "	.
	                            "label, credits, title, "	.
	                            "reviewAuthor, genres, isBooleans, " .
                              "mainPerformerId, titleAscii, mainPerformerAscii " .
                              ") values ( " .
                              "?, ?, ?," .
                              "?, ?, ?," .
                              "?, ?, ?," .
                              "?, ?, ? ) ";

my $INSERT_TO_MUSIDCDBALBUM     =  "insert into RoonDBMusicDBAlbum ( " .
	                                 "title, country, label, " .
	                                 "catalog, productCode, genres, " .
	                                 "year, albumId, metadataAlbumId, " .
	                                 "mainPerformerId, isBooleans, titleAscii, " .
                                   "mainPerformerAscii " .
                                   ") values ( " .
                                   "?, ?, ?," .
                                   "?, ?, ?," .
                                   "?, ?, ?," .
                                   "?, ?, ?, " .
                                   "?  ) ";

my $INSERT_INTO_ROON_ALBUM = "insert into roonAlbum ( " .
                              "albumId, title, year, " .
                              "isBooleans, mainPerformerId, genres, " .
                              "label, reviewText, credits, " .
                              "reviewAuthor, country, catalog, " .
                              "productCode, musicDBId, titleAscii, " .
                              "mainPerformerAscii, source, performedByTxt, " .
                              "performedByTxtAscii, imageUrl, alternateAlbumIds " .
                              ") values ( " .
                              "?, ?, ?," .
                              "?, ?, ?," .
                              "?, ?, ?," .
                              "?, ?, ?, " .
                              "?, ?, ?, " .
                              "?, ?, ?, " .
                              "?, ?, ? ) ";

my $INSERT_ALBUM_ID_ALTERNATE =   "insert into roonAlbumAltIDs " .
                                  "( albumId, alternateId ) " .
                                  "values " .
                                  "( ?, ? ) ";

my $UPDATE_ROON_ALBUM_W_MUSICDB = "Update roonAlbum " .
                                  "Set " .
                                  "country = ?,  " .
                                  "catalog = ?, " .
                                  "productCode = ?, " .
                                  "musicDBId = ?, " .
                                  "source = ?, " .
                                  "isBooleans = coalesce(isBooleans, ?), " .
                                  "genres = coalesce(genres, ?), " .
                                  "year = coalesce(year, ?), " .
                                  "performedByTxt = ?, " .
                                  "performedByTxtAscii = ? " .
                                  "Where albumId = ? ";

my $UPDATE_ROON_ALBUM_ADD_PATH =  "update roonAlbum " .
                                  "set path = ? " .
                                  "where albumId = ? ";

my $DELETE_ROON_ALBUM_BY_ID = "delete from roonAlbum where id = ?";

my $GET_ROON_ALBUM_BY_ASCII =   "select * from roonAlbum " .
                                "order by " .
                                "roonAlbum.titleAscii, " .
                                "roonAlbum.mainPerformerAscii, " .
                                "roonAlbum.source ";

my $GET_ROONALBUM_BY_ALBUMID =  "select * from roonAlbum " .
                                "where albumId = ?";

my $GET_ROON_ALBUM_BY_ALBUMASCII_TITLEASCII = "select * from roonAlbum " .
                                              "where titleAscii = ? AND " .
                                              "mainPerformerAscii = ? " .
                                              "order by path DESC";

my $GET_ROON_ALBUM_BY_ALBUMASCII_PRFRMBYTXTASC =  "select * from roonAlbum " .
                                                  "where titleAscii = ? AND " .
                                                  "performedByTxtAscii = ? " .
                                                  "order by path DESC";

# ------------------------- TRACK SQLS  ------------------------------


my $SELECT_MUSICDB_TRACK =  "select * from roonDB " .
                            "where " .
                            "valueHex like '%4d7573696344622e4c6f63616c547261636b%' AND " .
                            "valueHex like '%8709497344656c65746564%'"; #isdDeleted false

my $GET_SOOLOS_TRACK =    "select * from roonDB " .
                          "where " .
                          "valueHex like '%536f6f6c6f6f732e4d73672e4d657461646174612e547261636b%'";

my $INSERT_TO_MUSICDBTRACK = "insert into RoonDBMusicDBTrack (" .
	                           "trackId, albumId, path, " .
                             "title, trackNumber, mediaNumber, " .
                             "metadataTrackId, year, workName, "	.
                             "partName, credits, albumPerformer, " .
                             "albumTitle, trackPerformer " .
                             ") values ( " .
                             "?, ?, ?, " .
                             "?, ?, ?, " .
                             "?, ?, ?, " .
                             "?, ?, ?, " .
                             "?, ? ) ";

my $INSERT_TO_SOOLOOSTRACK = "insert into RoonSooloosTrack (" .
                             "trackId, albumId, credits, " .
                             "lengthSecond, mediaCount, mediaNumber, " .
                             "partId, partName, performanceId, "	.
                             "performanceLoc, sectionName, title, " .
                             "trackNumber, workName, workSeqnum, " .
                             "isBooleans " .
                             ") values ( " .
                             "?, ?, ?, " .
                             "?, ?, ?, " .
                             "?, ?, ?, " .
                             "?, ?, ?, " .
                             "?, ?, ?, " .
                             "? ) ";

my $INSERT_TO_ROONTRACK =  "insert into roonTrack ( " .
	                         "trackId, title, albumId, " .
	                         "trackNumber, mediaNumber, workName, " .
	                         "partName, credits, path, " .
	                         "musicDBId, year, albumPerformer, " .
	                         "albumTitle, trackPerformer, length, " .
	                         "mediaCount, partId, performanceId, " .
	                         "performanceLoc, sectionName, workSeqNum, " .
	                         "isBooleans, titleAscii, performerAscii, " .
	                         "albumAscii, albumPerformerAscii, source " .
                           ") values ( " .
                           "?, ?, ?," .
                           "?, ?, ?," .
                           "?, ?, ?," .
                           "?, ?, ?," .
                           "?, ?, ?," .
                           "?, ?, ?," .
                           "?, ?, ?," .
                           "?, ?, ?," .
                           "?, ?, ? ) ";

my $UPDATE_ROONTRACK_W_MUSICDB =  "Update roonTrack " .
                                  "Set " .
                                  "path = ?, " .
                                  "musicDBId = ?, " .
                                  "year = ?, " .
                                  "albumPerformer = ?, " .
                                  "albumTitle = ?, " .
                                  "trackPerformer = ?, " .
                                  "title = ?, " .
                                  # "titleAscii = ?, " .
                                  "performerAscii = ?, " .
                                  "albumAscii = ?, " .
                                  "albumPerformerAscii = ?, " .
                                  "source = ? " .
                                  "where trackId = ? ";

my $GET_ROON_TRACK_BY_ASCII = "select * from roonTrack " .
                              "order by " .
                              "roonTrack.titleAscii, " .
                              "roonTrack.albumAscii, " .
                              "roonTrack.albumPerformerAscii, " .
                              "roonTrack.source ";

my $GET_ROON_TRACK = "select * from roonTrack ";

my $DELETE_ROON_TRACK_BY_ID = "delete from roonTrack where id = ?";

my $GET_ROON_TRACKS_BY_ALBUM_ID =   "select * from roonTrack " .
                                    "where albumId = ? " .
                                    "ORDER BY " .
                                    "roonTrack.mediaNumber, trackNumber, path DESC ";


# ------------------------- PERFORMANCE SQLS  ------------------------------

my $GET_SOOLOOS_PERFORMANCE = "select * from roonDB " .
                              "where " .
                              "valueHex like '%536f6f6c6f6f732e4d73672e4d657461646174612e506572666f726d616e6365%'";

my $INSERT_TO_SOOLOOSPERFORMANCE  = "insert into RoonPerformance (" .
                                    "performanceId, workId, trackCount, " .
                                    "lengthSecond " .
                                    ") values ( " .
                                    "?, ?, ?, " .
                                    "? ) ";


# ------------------------- WORK SQLS  ------------------------------

my $GET_SOOLOOS_WORK =        "select * from roonDB " .
                              "where " .
                              "valueHex like '%536f6f6c6f6f732e4d73672e4d657461646174612e576f726b%'";

my $INSERT_TO_SOOLOOSWORK  =  "insert into RoonWork (" .
                              "workId, composer, title, " .
                              "year, parts, description, " .
                              "section, genres, period, " .
                              "form " .
                              ") values ( " .
                              "?, ?, ?," .
                              "?, ?, ?," .
                              "?, ?, ?," .
                              "? ) ";

my $INSERT_TO_ROON_WORK_PART = "insert into roonWorkPart ( " .
	                             "workId, partId, partNo, " .
	                             "title, sectionId " .
                               ") values ( " .
                               "?, ?, ?," .
                               "?, ? ) ";

my $INSERT_TO_ROON_WORK_SECTION =  "insert into roonWorkSection ( " .
	                                 "workId, sectionId, title " .
                                   ") values ( " .
                                   "?, ?, ? ) ";

my $GET_ROON_WORK = "select * from roonWork ";

# ------------------------- RELATIONSHIP SQLS  ------------------------------

my $INSERT_TO_ROON_PERFORMER_RELS =  "insert into roonPerformerRelationship (" .
	                                   "performerId, otherPerformerId, relationshipType, " .
                                     "score " .
                                     ") values ( " .
                                     "?, ?, ?, " .
                                     "? ) ";

my $INSERT_TO_ROON_PERFORMER_KNOWNAS =  "insert into roonPerformerAlsoKnownAs ( " .
                                     	  "performerId, alsoKnownAs "	.
                                        ") values ( " .
                                        "?, ? ) ";

my $INSERT_TO_ROON_GENRE = "insert into roonGenre ( " .
	                         "mapTo, mapToId, genre " .
                           ") values ( " .
                           "?, ?, ?) ";

my $INSERT_TO_MAINPERFORMER =  "insert into roonMainPerformers ( " .
	                             "mapTo, mapToId, performerId " .
                               ") values ( " .
                               "?, ?, ? ) ";

my $INSERT_TO_ROONCREDIT = "insert into roonCredit ( " .
	                         "mapTo, mapToId, performerId, " .
	                         "performerType, performerCategory " .
                           ") values ( " .
                           "?, ?, ?, " .
                           "?, ? ) ";

my $INSERT_TO_ROONISBOOLEAN =  "insert into roonIsBoolean ( " .
	                             "mapTo, mapToId, name " .
                               ") values ( " .
                               "?, ?, ? ) ";

my $INSERT_TO_ROONLABEL =  "insert into roonLabel ( " .
	                         "mapTo, mapToId, label " .
                           ") values ( " .
                           "?, ?, ? ) ";

my $GET_PERFORMER_NAME_FROM_KNOWNAS = "select roonPerformer.name " .
                                      "from roonPerformer, roonPerformerAlsoKnownAs " .
                                      "where " .
                                      "roonPerformer.performerId = roonPerformerAlsoKnownAs.performerId AND " .
                                      "roonPerformerAlsoKnownAs.alsoKnownAs = ? ";

my $DELETE_TABLES = "Delete from roonAlbum; " .
                    "Delete from roonAlbumPerformers; " .
                    "Delete from roonCredit; " .
                    "Delete from roonGenre; " .
                    "Delete from roonIsBoolean; " .
                    "Delete from roonLabel; " .
                    "Delete from roonPerformance; " .
                    "Delete from roonPerformer; " .
                    "Delete from roonPerformerAlsoKnownAs; " .
                    "Delete from roonPerformerRelationship; " .
                    "Delete from roonTrack; " .
                    "Delete from roonWork; " .
                    "Delete from roonWorkPart; " .
                    "Delete from roonWorkSection; ";

my $GET_MAIN_PERFORMER_FROM_ROONAPI_TITLEASCII =  "select " .
                                                  "roonTrack.trackId, " .
                                                  "roonTrack.albumId, " .
                                                  "roonAlbum.path, " .
                                                  "roonAlbum.title as albumTitle, " .
                                                  "roonAlbum.performedByTxt as albumArtist, " .
                                                  "roonCredit.mapToId, " .
                                                  "roonPerformer.nameAscii " .
                                                  "FROM " .
                                                  "roonTrack, roonCredit, roonPerformer, roonAlbum " .
                                                  "WHERE " .
                                                  "roonTrack.trackId = roonCredit.mapToId AND " .
                                                  "roonCredit.performerId = roonPerformer.performerId AND " .
                                                  "roonCredit.performerType = 'Primary Artist' AND " .
                                                  "roonAlbum.albumId = roonTrack.albumId AND " .
                                                  "roonTrack.titleAscii = ? " .
                                                  "order by roonAlbum.path DESC ";

my $SPLITTER = "05 03";

&connectDB();

#------------------------- ROONDB SETUPS ------------------------------------
#&processRoonDBAll(); -> DON'T USE
# &processRoonDBSelected();

#------------------------- RETRIEVE FROM DB ---------------------------------
&retrieveMusicDBPerformer();
&retrieveSooloosPerformer();
&retrieveSooloosAlbum();
&retrieveMusicDBAlbum();
&retrieveSooloosPerformance();
&retrieveSooloosWork();
&retrieveSooloosTrack();
&retrieveMusicDBTrack();

#----------------------- INITIAL SETUPS -------------------------------------
&setupRoonAPIs();
&setupRoonTrack();
&setupRoonAlbum();
&setupRoonPerformer();
&setupRoonWork();

#----------------------- MATCH PROCESS -------------------------------------
&matchRoonAPIs();

#------------------------------ HELPERS ------------------------------------

#&testGetPerformerByPerformerId();
#&testGetAlbumByAlbumId();
#&testGetPerformerNameFromAlsoKnownAs();

&disconnectDB();


#------------------------------ROONDB SUBS ---------------------------------
sub processRoonDBAll {
  print "START process updating roonDB - ALL DATA\n";

  &processRoonDB( $$GET_ROON_DB );

  print "FINISHED process updating roonDB - ALL DATA\n";
}

sub processRoonDBSelected {
  print "START process updating roonDB\n";

  my $start_time = time();
  print "- Start importing from musicDB Person\n";
  &processRoonDB( $SELECT_MUSICDB_PERSON );
  print "- Finished importing from musicDB Person\n";

  print "- Start importing from sooloos Person\n";
  &processRoonDB( $GET_SOOLOOS_PERFORMER );
  print "- Finished importing from sooloos Person\n";

  print "- Start importing from musicDB Album\n";
  &processRoonDB( $SELECT_MUSICDB_ALBUM );
  print "- Finished importing from musicDB Album\n";

  print "- Start importing from sooloos Album\n";
  &processRoonDB( $GET_SOOLOOS_ALBUM );
  print "- Finished importing from sooloos Album\n";

  print "- Start importing from musicDB Track\n";
  &processRoonDB( $SELECT_MUSICDB_TRACK );
  print "- Finished importing from musicDB Track\n";

  print "- Start importing from sooloos Track\n";
  &processRoonDB( $GET_SOOLOS_TRACK );
  print "- Finished importing from sooloos Track\n";

  print "- Start importing from sooloos Performance\n";
  &processRoonDB( $GET_SOOLOOS_PERFORMANCE );
  print "- Finished importing from sooloos Performance\n";

  print "- Start importing from sooloos work\n";
  &processRoonDB( $GET_SOOLOOS_WORK );
  print "- Finished importing from sooloos work\n";

  my $end_time = time();

  print "FINISHED process updating roonDB in " . $start_time - $end_time . " miliseconds\n";
}


#------------------------------ROON API SUBS -------------------------------
sub matchRoonAPIs {
  print "START process matchRoonAPIs\n";

  my $sth = $dbh->prepare( $GET_ROON_APIS );
  my $updArtistSth = $dbh->prepare( $UPDATE_ROON_APIS_WITH_ROONPERFORMER );
  my $updTrackSth = $dbh->prepare( $UPDATE_ROON_APIS_WITH_ROONTRACK );
  my $updAlbumSth = $dbh->prepare( $UPDATE_ROON_APIS_WITH_ROONALBUM );
  my $updObjLevel = $dbh->prepare( $UPDATE_ROON_APIS_OBJLEVEL );
  my $missingAlbumSth = $dbh->prepare( $GET_UNMATCHED_ALBUMS );
  my $GET_ROONAPIS_BY_SEQUENCESth = $dbh->prepare( $GET_ROONAPIS_BY_SEQUENCE );
  my $GET_ROONAPERFORMERS_BY_TITLEASCII = $dbh->prepare( $GET_MAIN_PERFORMER_FROM_ROONAPI_TITLEASCII );
  my $insertBoxSet = $dbh->prepare( $INSERT_INTO_ROONAPI_BOXSET );

  my $performerNameSql = "select name from roonPerformer where performerId = ? ";

  $sth->execute();

  my @curTracks;
  my $curArtist;
  my $ctr = 0;
  my $isVariousArtistDone = 0;
  my $trackSequence = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my $id = $row->{'id'};
    my $level = $row->{'level'};
    my $artistAscii = $row->{'artistsAscii'};
    my $albumAscii = $row->{'albumAscii'};
    my $titleAscii = $row->{'titleAscii'};
    my $subtitleAscii = $row->{'subtitleAscii'};
    my $sequence = $row->{'sequence'};
    my $path = $row->{'path'};

    my $artistPath = &getPrevLevelPath($path);

    if ( $level =~ m/artist/ && $row->{'hint'} =~ m/^list$/ ) {
      $updObjLevel->execute( 1, 0, $id);
      $curArtist = $row;

      # if ( $isVariousArtistDone == 0 && $path =~ m/Various Artists/ ) {
      #   my $varArt = &getSingleDBRow("select * from roonApis where title = ? and level = 'artist'", "Various Artists");
      #   my $rPerf =  &getSingleDBRow("select performerId from roonPerformer where name = ?", "Various Artists");
      #   my $updVarArt = $dbh->prepare("update roonApis set path = ?, performerId = ? where id = ?");
      #
      #   $path =~ m/^(.*?\/Various Artists)/;
      #   $updVarArt->execute( $1, $rPerf->{'performerId'}, $varArt->{'id'});
      #   $dbh->commit();
      #
      #   $isVariousArtistDone = 1;
      # }
    } elsif ( $level =~ m/album/ && $subtitleAscii !~ m/^$/ ) {
      my @albums;
      if ( $titleAscii !~ m/^$/ && $artistAscii !~ m/^$/ ) {
        @albums = &getArrayDBRowsTwoFields($GET_ROON_ALBUM_BY_ALBUMASCII_TITLEASCII, $titleAscii, $artistAscii);
      }

      if (( $#albums < 0 && $titleAscii !~ m/^$/ && $subtitleAscii !~ m/^$/ ) || ( $#albums >= 0 && $albums[0]->{'path'} =~ m/^$/ )) {
        my @albumsNow = &getArrayDBRowsTwoFields($GET_ROON_ALBUM_BY_ALBUMASCII_TITLEASCII, $titleAscii, $subtitleAscii);

        if ( $#albumsNow >= 0 ) {
          @albums = @albumsNow;
        }
      }

      if ( $#albums < 0 || ( $#albums >= 0 && $albums[0]->{'path'} =~ m/^$/ ) ) {
        my @albumsNow = &getArrayDBRowsTwoFields($GET_ROON_ALBUM_BY_ALBUMASCII_PRFRMBYTXTASC, $titleAscii, $subtitleAscii);

        if ( $#albumsNow >= 0 ) {
          @albums = @albumsNow;
        }
      }

      if ( $#albums < 0 ) {
        my $trackSeq = $sequence;
        $trackSeq = $trackSeq . "|1-1";
        my $track = &getSingleDBRow($GET_ROONAPIS_BY_SEQUENCE, $trackSeq);
        my @performers = &getArrayDBRows($GET_MAIN_PERFORMER_FROM_ROONAPI_TITLEASCII, $track->{'titleAscii'});

        foreach my $curPerformer (@performers) {
          chomp($curPerformer);

          if ( $track->{'artistsAscii'} eq $curPerformer->{'nameAscii'} && $track->{'artistsAscii'} !~ m/^$/) {
            $updAlbumSth->execute( $curPerformer->{'path'}, $curPerformer->{'albumId'}, $curPerformer->{'albumArtist'}, $curPerformer->{'albumTitle'}, $curPerformer->{'id'}, $id);

            @albums = &getArrayDBRows($GET_ROONALBUM_BY_ALBUMID, $curPerformer->{'albumId'});
          }
        }
      }

      if ( $#albums >= 0) {
        my $artistFound = 0;
        my $curAlbum = $albums[0];

        if ( $isVariousArtistDone == 0 && $curAlbum->{'path'} =~ m/Various Artists/ ) {
          my $varArt = &getSingleDBRow("select * from roonApis where title = ? and level = 'artist'", "Various Artists");
          my $rPerf =  &getSingleDBRow("select performerId from roonPerformer where name = ?", "Various Artists");
          my $updVarArt = $dbh->prepare("update roonApis set path = ?, performerId = ? where id = ?");

          $curAlbum->{'path'} =~ m/^(.*?\/Various Artists)/;
          $updVarArt->execute( $1, $rPerf->{'performerId'}, $varArt->{'id'});
          $dbh->commit();

          $isVariousArtistDone = 1;
        }

        my $artistSeq = $sequence;
        $artistSeq =~ s/\|\d+\-\d+$//;

        my $roonApiArtist = &getSingleDBRow($GET_ROONAPIS_BY_SEQUENCE, $artistSeq);

        if ( $roonApiArtist->{'performerId'} =~ m/^$/ || $roonApiArtist->{'path'} =~ m/^$/) {
          my $artistPath = $curAlbum->{'path'};

          if ( $artistPath =~ m/Various Artists/ ) {
            $artistPath = &getPrevLevelPath($artistPath);
          } else {
            while ( $artistPath =~ m/Box Sets/ ) {
              $artistPath = &getPrevLevelPath($artistPath);
            }
          }

          my @mainPerformers = &getMainPerformersFromAlbum( $curAlbum->{'albumId'} );

          foreach my $curPerformer (@mainPerformers) {
            if ( $$artistFound == 0 && $curPerformer->{'nameAscii'} eq $roonApiArtist->{'titleAscii'}) {
              $artistFound = 1;

              my $artistName = &getSingleDBRow( $performerNameSql, $curPerformer->{'performerId'});
              $updArtistSth->execute( $artistPath, $artistName->{'name'}, $curPerformer->{'performerId'}, $roonApiArtist->{'id'});
            }
          }

          if ( $artistFound == 0 ) {
            my $artist = &getSingleDBRow( $GET_PERFORMER_BY_NAMEASCII, $roonApiArtist->{'artistsAscii'});

            if ( $artist->{'performerId'} !~ m/^$/ ) {
              $artistFound = 1;

              my $artistName = &getSingleDBRow( $performerNameSql, $curPerformer->{'performerId'});
              $updArtistSth->execute( $artistPath, $artistName->{'name'}, $artist->{'performerId'}, $roonApiArtist->{'id'});
            }
          }
        }

        if ( $curAlbum->{'path'} =~ m/Box Sets/ ) {
          my $bset;

          $curAlbum->{'path'} =~ m/^(.*?\/Box Sets\/.*?)\//;
          $bset->{'path'} = $1;

          my $boxSet = &getSingleDBRow( $GET_ROONAPIS_BY_PATH, $bset->{'path'});

          if ( $boxSet->{'path'} !~ m/^$/ ) {
              $updObjLevel->execute( 3, $boxSet->{'id'}, $id );
          } else {
            my $artPath = $bset->{'path'};
            $artPath =~ m/^(.*?)\/Box Sets/;
            $artPath = $1;

            my $artistNow = &getSingleDBRow( $GET_ROONAPIS_BY_PATH, $artPath);

            $artPath =~ m/^(.*?)\/Box Sets/;
            $bset->{'title'} = $curAlbum->{'path'};
            $bset->{'title'} =~ s/^.*Box Sets\///;
            $bset->{'title'} =~ s/\/.*//;
            $bset->{'hint'} = "list";
            $bset->{'subtitle'} = $bset->{'title'};
            $bset->{'level'} = "boxset";


            $dbh->commit();
            $insertBoxSet->execute( $artistNow->{'id'}, $bset->{'title'}, $bset->{'subtitle'},
                                    $bset->{'hint'}, $bset->{'level'}, $artistNow->{'title'},
                                    $bset->{'title'}, $bset->{'path'}, 2 );
            $dbh->commit();
            $updObjLevel->execute( 3, $dbh->sqlite_last_insert_rowid, $id);
            $dbh->commit();
          }
        } else {
          my $updNow = $dbh->prepare("update roonApis set objLevel = ? where id = ?");
          $updNow->execute( 2, $id );
        }

        $updAlbumSth->execute( $curAlbum->{'path'}, $curAlbum->{'albumId'}, $curAlbum->{'performedByTxt'}, $curAlbum->{'title'}, $curAlbum->{'year'}, $id);

        @curTracks = &getTracksByAlbumId( $curAlbum->{'albumId'} );
      } else {
        @curTracks = ();
      }

      $trackSequence = 0;
    } elsif ( $level =~ m/track/ ) { #&& $subtitleAscii !~ m/^$/) {
      $updTrackSth->execute( $curTracks[$trackSequence]->{'path'}, $curTracks[$trackSequence]->{'trackId'}, $id);
      $trackSequence = $trackSequence + 1;
      # foreach my $currentTrack (@curTracks) {
      #   if ( $titleAscii eq $currentTrack->{'titleAscii'} ) {
      #     $updTrackSth->execute( $currentTrack->{'path'}, $currentTrack->{'trackId'}, $id);
      #   }
      # }
    }

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  # FIX BOXSET PARENTID
  my $varSql = "select " .
               "roonApis.id,  " .
               "roonApis.parentId, " .
               "roonapis.album,  " .
               "roonapis.sequence, " .
               "roonapis.path " .
               "from roonApis " .
               "where " .
               "roonApis.path like '\%/Box Sets/\%' AND " .
               "level = 'album'";

  my $parSql = "select id, parentId from roonApis where sequence = ? ";
  my $updVarSql = "update roonApis set parentId = ?,  boxsetId = ? where id = ?";

  my $varSth = $dbh->prepare( $varSql );
  my $updVarSth = $dbh->prepare( $updVarSql );

  $varSth->execute();

  while ($row = $varSth->fetchrow_hashref()) {
    $sequence = $row->{'sequence'};
    $sequence =~ m/^(.*?)\|\d+\-\d+$/;

    $id = &getSingleDBRow( $parSql, $1);
    $updVarSth->execute( $id->{'id'}, $row->{'parentId'}, $row->{'id'});
  }

  # FIX ALBUMS WITH NO ARTIST INFO
  my $albumNoArtistSql =  "select " .
                          "roonApis.id, " .
                          "roonApis.albumId, " .
                          "roonApis.artist, " .
                          "roonApis.album " .
                          "from roonApis " .
                          "where " .
                          "roonApis.level = 'album' AND " .
                          "roonApis.image_key is not null AND " .
                          "roonApis.artist is  NULL";

  my $insertArtistUpdateSth = $dbh->prepare( "update roonApis set artist = ? where id = ?" );
  my $albumNoArtistSth = $dbh->prepare( $albumNoArtistSql );

  $albumNoArtistSth->execute();
  while ($row = $albumNoArtistSth->fetchrow_hashref()) {
    my $artistName = &getSingleDBRow("select mainPerformerId from roonAlbum where albumId = ? ", $row->{'albumId'});

    my @names = ($artistName->{'mainPerformerId'} =~ m/\[\[.*?\|(.*?)\]\]/g );
    my $fullArtist = "";

    foreach my $curName (@names) {
      chomp($curName);

      $fullArtist = $fullArtist . " / " if ( $fullArtist !~ m/^$/ );
      $fullArtist = $fullArtist . $curName;
    }

    $insertArtistUpdateSth->execute($fullArtist, $row->{'id'});
  }

  $dbh->commit() or die $dbh->errstr;
  print "FINISHED process matchRoonAPIs\n";
}

sub setupRoonAPIs {
  print "START process setupRoonAPIs\n";

  my $sth = $dbh->prepare( $GET_ROON_APIS_ALBUM );
  my $inSth = $dbh->prepare( $UPDATE_ROON_APIS_BY_IMAGEKEY );

  my $initSth = $dbh->prepare( $REFRESH_ROON_APIS );

  $initSth->execute();

  $initSth = $dbh->prepare( $REMOVEARTIST_ON_ROON_APIS );
  $initSth->execute();

  $sth->execute();

  my $ctr = 0;
  my $curAlbum;

  print "- processing inital album\n";
  while ($row = $sth->fetchrow_hashref()) {
    $ctr++;

    my $title = $row->{'title'};
    my $artist = $row->{'artist'};
    my $image_key = $row->{'image_key'};

    if ( $image_key !~ m/^$/ ) {
      if ( $curAlbum->{'image_key'} !~ m/^${image_key}$/ ) {
        %{$curAlbum} = ();
      }

      my $titleAscii = &getFieldAscii($title);

      my $subtitle = &getPerformerNameFromAlsoKnownAs($row->{'subtitle'});

      if ( $subtitle =~ m/^$/ ) {
        $subtitle = $row->{'subtitle'};
      }

      $subtitle =~ s/[^a-zA-Z0-9,\(\)]//g;
      $subtitle = &sortString($subtitle);

      my $artistName = &getPerformerNameFromAlsoKnownAs($curAlbum->{'artist'});

      if ( $artistName =~ m/^$/ ) {
        $artistName = $curAlbum->{'artist'};
      }

      $artistsAscii = &getFieldAscii($artist . $artistName);

      $inSth->execute($title, $titleAscii, $titleAscii, $artistsAscii, $subtitle, $image_key );

      if ($ctr % 100 == 0) {
        $dbh->commit() or die $dbh->errstr;
        print "Counter: $ctr\n";
      }
    }

    $curAlbum = $row;
    $curAlbum->{'artist'} = $artistsAscii;
  }

  $dbh->commit() or die $dbh->errstr;
  print "- finished processing initial album\n";
  print "- processing rest data\n";

  $ctr = 0;
  %{$curAlbum} = ();

  $sth = $dbh->prepare( $GET_ROON_APIS );
  $inSth = $dbh->prepare( $UPDATE_ROON_APIS_BY_ID );

  $sth->execute();

  while ($row = $sth->fetchrow_hashref()) {
    $ctr++;

    my $title = $row->{'title'};
    my $artist = $row->{'artist'};
    my $subtitle = $row->{'subtitle'};
    my $image_key = $row->{'image_key'};
    my $level = $row->{'level'};
    my $album = $row->{'album'};
    my $id = $row->{'id'};

    my $titleAscii = $title;
    $titleAscii =~ s/^[0-9\-\.]*//;
    $titleAscii =~ s/^\s*//;
    $titleAscii = &getFieldAscii($titleAscii);

    my $subtitleAscii = &getFieldAscii($subtitle);

    if ( $row->{'level'} =~ m/artist/ ) {
      %{$curAlbum} = ();
      $inSth->execute($artist, "", "", $titleAscii, $titleAscii, $subtitleAscii, $id );
    } elsif ( $row->{'level'} =~ m/album/ && $subtitle !~ m/^$/ ) {
      $curAlbum = $row;
    } elsif ( $row->{'level'} =~ m/track/ && ($subtitle !~ m/^$/ || $subtitle == null )) {

      $inSth->execute($subtitle, $curAlbum->{'album'}, $curAlbum->{'albumAscii'}, $titleAscii, $curAlbum->{'artistsAscii'}, $subtitleAscii, $id );
    }

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }
  }

  $dbh->commit() or die $dbh->errstr;
  print "- finished processing rest data\n";


  print "Finished $ctr records\n";
  print "END process setupRoonAPIs\n";
}


#--------------------------- PERFORMER SUBS ------------------------------
sub setupRoonPerformer {
  print "START process setupRoonPerformer\n";

  my $sth = $dbh->prepare( $GET_ROON_PERFORMERS );
  my $inSth = $dbh->prepare( $INSERT_TO_ROON_PERFORMER_RELS );
  my $akaStr = $dbh->prepare( $INSERT_TO_ROON_PERFORMER_KNOWNAS );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {

    &insertPerformerIdAlts( $row->{'altIds'}) if ( $row->{'altIds'} !~ m/^$/);

    my $relationships = $row->{'relationships'};
    my @relations = ($relationships =~ m/\[\[(.*?)\]\]/g );

    foreach my $curRel (@relations) {
      chomp($curRel);

      if ($curRel !~ m/^$/) {
        $curRel =~ m/^(.*?)\|(.*?)\|(.*?)\|(.*)$/;
      $inSth->execute($1, $3, $2, $4 );
      }
    }

    my $alsoKnownAs = $row->{'alsoKnownAs'};
    my @knownAs = ($alsoKnownAs =~ m/\[\[(.*?)\]\]/g );

    foreach my $curKnownAs (@knownAs) {
      chomp($curKnownAs);

      if ( $curKnownAs !~ m/^$/ ) {
        $curKnownAs =~ m/^(.*?)\|(.*)$/;
        $akaStr->execute($1, $2 );
      }
    }

    my $genre = $row->{'genres'};
    my @genres = ($genre =~ m/\[\[(.*?)\]\]/g );

    foreach my $curGenre (@genres) {
      chomp($curGenre);
      if ( $curGenre !~ m/^$/ ) {
        &insertGenre("performer", $row->{'performerId'}, $curGenre);
      }
    }

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;

  }

  $dbh->commit() or die $dbh->errstr;
  print "Finished process setupRoonPerformer\n";
}

sub retrieveSooloosPerformer {
  print "START process sooloosPerformer\n";

  my $sth = $dbh->prepare( $GET_SOOLOOS_PERFORMER );
  my $inSth = $dbh->prepare( $INSERT_TO_ROON_PERFORMER );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;

    my $valueString = $row->{'valueString'};
    my $valueHex = $row->{'valueHex'};

    my $currentField = "";

    $valueHex =~ s/..\K(?=.)/ /sg;

    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);

      $firstStr =~ s/\s//g;

      if ( $currentField =~ m/relationship/ ) {
        if ($firstStr =~ m/^.{12}(0{6}.*?)(0{6}.*?)(0{6}.*)/ ) {
          $variable{'relationship'} = $variable{'relationship'} . "[[" . $variable{'performerId'} . "|" .
                                      &getAscii(&getLengthText($1, 8)) . "|" . &getLengthText($2, 8) . "|" .
                                      &convertHexToDec($3) . "]]";
        } else {
          $currentField = "";
        }
      }

      if ( $variable{'image'} =~ m/^$/ && $firstStr =~ m/^.{12}(0+.{2}68747470(73)?3a2f2f.*)506572666f726d6572496d616765/ ) {
        $variable{'image'} = &getAscii(&getLengthText($1, 8));

        $variable{'image'} =~  m/(\.[^.]+)$/;
        my $filename = "img/" . $variable{'performerId'} . $1;
        &downloadFile( $variable{'image'}, $filename) if ( ! -e $filename );

      }

      if ( $currentField =~ m/^$/ ) {
        if ( $firstStr =~ m/0b506572666f726d65724964(00+.*)/) { # performerId
          $variable{'performerId'} = &getLengthText($1, 8);
        }

        if ($firstStr =~ m/536f75726365506572666f726d6572496473(.*?)044e616d65/ ) {
          my $perfIds = $1;

          while ( $perfIds =~ s/(^0{6}.*?)(0{6}|$)/$2/) {
            $curId = &getLengthText($1, 8);
            $variable{'altPerfIds'} = $variable{'altPerfIds'} . "[[" . $variable{'performerId'} . "|" . $curId . "]]";
          }
        }

        if ( $firstStr =~ m/81044e616d65(00+.*)/ ) { # performer name
          $variable{'name'} = &getAscii(&getLengthText($1, 8));
          $variable{'nameAscii'} = &getFieldAscii($variable{'name'});
        }

        if ( $firstStr =~ m/0454797065(00+.*)/ ) { # performer type
          $variable{'type'} = &getAscii(&getLengthText($1, 8));
        }

        if ( $firstStr =~ m/0942696f677261706879.{6}0454657874(00+.*)/ ) { # biography text
          $variable{'biographyText'} = &getAscii(&getLengthText($1, 8));
        }

        if ( $firstStr =~ m/06417574686f72(00+.*)/ ) { # biography author
          $variable{'biographyAuthor'} = &getAscii(&getLengthText($1, 8));
        }

        if ( $firstStr =~ m/0a4269727468506c616365(00+.*)/ ) { # birth place
          $variable{'birthPlace'} = &getAscii(&getLengthText($1, 8));
        }

        if ( $firstStr =~ m/0459656172(.{8})/ ) { # birth year
          $variable{'birthYear'} = &convertHexToDec($1);
        }

        if ( $firstStr =~ m/07436f756e747279(00+.*)/ ) { # country
          $variable{'country'} = &getAscii(&getLengthText($1, 8));
        }

        if ( $firstStr =~ m/0647656e726573(00+.*)06496d61676573/ ) { # genres
          my $value = $1;
          $value =~ s/..\K(?=.)/ /sg;

          while ( $value =~ s/(^00 00 00.*?)(00 00 00|$)/$2/) {
            my $mygenre = $1;
            $mygenre =~ s/\s//g;
            $variable{"genres"} = $variable{"genres"} . "[[" . &getAscii(&getLengthText($mygenre, 8)) . "]]";
          }
        }

        if ( $firstStr =~ m/0b416c736f4b6e6f776e4173(00+.*)?0b4465736372697074696f6e|0454797065/ ) { # alsoKnownAs
          my $value = $1;
          $value =~ s/..\K(?=.)/ /sg;

          while ( $value =~ s/(^00 00 00.*?)(00 00 00|$)/$2/) {
            my $knownAs = $1;
            $knownAs =~ s/\s//g;
            $variable{"alsoKnownAs"} = $variable{"alsoKnownAs"} . "[[" . $variable{'performerId'} . "|" . &getAscii(&getLengthText($knownAs, 8)) . "]]";
          }
        }

        if ( $firstStr =~ m/0d52656c6174696f6e7368697073.*?(0{6}.*?)(0{6}.*?)(0{6}.*)/ ) { # relationship
          my $curRel = &getPerformerByPerformerId(&getLengthText($2, 8));
          $variable{'relationship'} = "[[" . $variable{'performerId'} . "|" .
                                      &getAscii(&getLengthText($1, 8)) . "|" . &getLengthText($2, 8) . "|" .
                                      &convertHexToDec($3) . "]]";
          $currentField = "relationship";
        }

        if ( $firstStr =~ m/0b4465736372697074696f6e(00+.*)/ ) { # description
          $variable{'description'} = &getAscii(&getLengthText($1, 8));
        }
      }
    }

    $inSth->execute($variable{'performerId'}, $variable{'name'}, $variable{'type'},
                    $variable{'birthYear'}, $variable{'relationship'}, $variable{'biographyText'},
                    $variable{'biographyAuthor'}, $variable{'description'}, $variable{'birthPlace'},
                    $variable{'genres'}, $variable{'country'}, $variable{'nameAscii'},
                    $variable{'image'}, $variable{'alsoKnownAs'}, "sooloos",
                    $variable{'altPerfIds'} );

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  $dbh->commit() or die $dbh->errstr;
  print "Finished process sooloosPerformer\n";
}

sub retrieveMusicDBPerformer {
  print "START process musicDBPerson\n";

  my $sth = $dbh->prepare( $SELECT_MUSICDB_PERSON );
  my $inSth = $dbh->prepare( $INSERT_TO_ROON_PERFORMER );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;

    my $valueString = $row->{'valueString'};
    my $valueHex = $row->{'valueHex'};

    $valueHex =~ s/..\K(?=.)/ /sg;

    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);
      $firstStr =~ s/\s//g;

      if ( $firstStr =~ m/0b506572666f726d65724964(00+.*)/ ) { # performerId
        $variable{'performerId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/044e616d65(00+.*)/ ) { # name
        $variable{'name'} = &getAscii(&getLengthText($1, 8));
        $variable{'nameAscii'} = &getFieldAscii($variable{'name'});
      }
    }

    $inSth->execute($variable{'performerId'}, $variable{'name'}, $variable{'type'},
                    $variable{'birthYear'}, $variable{'relationship'}, $variable{'biographyText'},
                    $variable{'biographyAuthor'}, $variable{'description'}, $variable{'birthPlace'},
                    $variable{'genres'}, $variable{'country'}, $variable{'nameAscii'},
                    $variable{'image'}, $variable{'alsoKnownAs'}, "musicDB",
                    "" );


    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  print "Finished $ctr records\n";
  print "END process musicDBPerson\n";
}

sub getPerformerNameFromAlsoKnownAs {
  my $name = &getSingleDBRow( $GET_PERFORMER_NAME_FROM_KNOWNAS, $_[0]);

  return $name->{'name'};
}

sub getMainPerformersFromAlbum {
  return &getArrayDBRows($GET_MAIN_PERFORMERS_FROM_ALBUM, $_[0] );
}

sub getPerformerByPerformerId {
  return &getSingleDBRow( $GET_ROONPERFORMER_BY_PERFORMERID, $_[0]);
}

sub getPerformersByMultipleIDs {
  my $text = $_[0];
  my $toReturn;

  if ( $text =~ m/\|\-\|/ ) {
    @ids = split(/\|\-\|/, $text);

    foreach my $curId (@ids) {
      chomp($curId);

      $toReturn = $toReturn . " / " if ( $toReturn !~ m/^$/ );
      my $curPerformer = &getPerformerByPerformerId($curId);
      $toReturn = $toReturn . $curPerformer->{'name'};
    }
  }

  return $toReturn
}

sub getPerformerByNameAscii {
  return &getSingleDBRow( $GET_PERFORMER_BY_NAMEASCII, $_[0]);
}

sub insertPerformerIdAlts {
  # my $performerId = $_[0];
  #
  my $insertAltPerfId = $dbh->prepare( $INSERT_PERF_ID_ALTERNATE );
  #
  # my $getAltPerfIds = &getSingleDBRow("select altIds from roonPerformer where performerId = ?", $performerId);
  # my $perfIds = $getAltPerfIds->{'altIds'};

  my $perfIds = $_[0];
  my @alternateIds = ($perfIds =~ m/\[\[(.*?)\]\]/g );

  foreach my $curIds (@alternateIds) {
    chomp($curIds);

    if ( $curIds !~ m/^$/ ) {
      $curIds =~ m/^(.*?)\|(.*)$/;
      $insertAltPerfId->execute($1, $2 );
    }
  }

  $dbh->commit() or die $dbh->errstr;
}

#--------------------------- ALBUM SUBS ------------------------------
sub setupRoonAlbum {
  print "START process setupRoonAlbum\n";

  my $prevAlbum;

  my $sth = $dbh->prepare( $GET_ROON_ALBUM_BY_ASCII );
  my $perfSth = $dbh->prepare( $INSERT_TO_MAINPERFORMER );
  my $crStr = $dbh->prepare( $INSERT_TO_ROONCREDIT );
  my $isBoolStr = $dbh->prepare( $INSERT_TO_ROONISBOOLEAN );
  my $lblStr = $dbh->prepare( $INSERT_TO_ROONLABEL );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my $id = $row->{'id'};
    my $albumId = $row->{'albumId'};
    my $titleAscii = $row->{'titleAscii'};
    my $mainPerformerAscii = $row->{'mainPerformerAscii'};
    my $source = $row->{'source'};
    my $altIds = $row->{'alternateAlbumIds'};

    &insertAlbumIdAlts($altIds); #populate roonAlbumAltIDs

    my $txt = $row->{'isBooleans'};
    my @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ($curVal !~ m/^$/) {
        $isBoolStr->execute("album", $albumId, $curVal );
      }
    }

    $txt = $row->{'mainPerformerId'};
    @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ($curVal !~ m/^$/) {
        $curVal =~ m/^(.*?)\|(.*?)$/;
        $perfSth->execute("album", $albumId, $1 );
      }
    }

    $txt = $row->{'genres'};
    @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ( $curVal !~ m/^$/ ) {
        &insertGenre("album", $albumId, $curVal);
      }
    }

    $txt = $row->{'label'};
    @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ($curVal !~ m/^$/) {
        $lblStr->execute( "album", $albumId, $curVal );
      }
    }

    $txt = $row->{'credits'};
    @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ($curVal !~ m/^$/) {
        $curVal =~ m/^(.*?)\|(.*?)\|(.*)$/;
        $crStr->execute( "album", $albumId, $1, $2, $3 );
      }
    }

    if ($ctr % 100 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
    $prevAlbum = $row;
  }

  $dbh->commit() or die $dbh->errstr;
  print "Finished process setupRoonAlbum\n";
}

sub insertAlbumIdAlts {
  # my $albumId = $_[0];

  my $insertAltAlbId = $dbh->prepare( $INSERT_ALBUM_ID_ALTERNATE );

  # my $getAltPerfIds = &getSingleDBRow("select alternateAlbumIds from roonAlbum where albumId = ?", $albumId);
  # my $perfIds = $getAltPerfIds->{'alternateAlbumIds'};
  my $perfIds = $_[0];
  my @alternateIds = ($perfIds =~ m/\[\[(.*?)\]\]/g );

  foreach my $curIds (@alternateIds) {
    chomp($curIds);

    if ( $curIds !~ m/^$/ ) {
      $curIds =~ m/^(.*?)\|(.*)$/;
      $insertAltAlbId->execute($1, $2 );
    }
  }
}

sub retrieveSooloosAlbum {
  print "START process sooloosAlbum\n";

  my $sth = $dbh->prepare( $GET_SOOLOOS_ALBUM );
  my $inSth = $dbh->prepare( $INSERT_INTO_ROON_ALBUM );
  # my $inSth = $dbh->prepare( $INSERT_TO_SOOLOOSALBUM );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;

    my $valueString = $row->{'valueString'};
    my $valueHex = $row->{'valueHex'};

    my $currentField = "";

    $valueHex =~ s/..\K(?=.)/ /sg;

    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);
      $firstStr =~ s/\s//g;

      if ( $currentField =~ m/^$/ ) {
        if ( $firstStr =~ m/416c62756d4964(0+.*)/ ) { # AlbumId
          $variable{'albumId'} = &getLengthText($1, 8);
        }

        if ( $firstStr =~ m/536f75726365416c62756d496473(.*?)526f6f6e52656c6561736547726f75704964/ ) { #Alternate Album IDs
          my $albIds = $1;

          while ( $albIds =~ s/(^0{6}.*?)(0{6}|$)/$2/) {
            my $curIds = &getLengthText($1, 8);
            $variable{'altAlbumIds'} = $variable{'altAlbumIds'} . "[[" . $variable{'albumId'} . "|" . $curIds . "]]";
          }
        }

        if ( $variable{'title'} =~ m/^$/ && $firstStr =~ m/81055469746c65(0+.*)/ ) { # Title
          $variable{'title'} = &getAscii(&getLengthText($1, 8));
          $variable{'titleAscii'} = &getFieldAscii($variable{'title'});
        }

        if ( $firstStr =~ m/526576696577.{8}54657874/ ) { #Review Text and Author
          if ( $firstStr =~ m/810454657874(0+.*)/ ) { #Review Text
            $variable{'reviewText'} = &getAscii(&getLengthText($1, 8));
          }

          if ( $firstStr =~ m/8106417574686f72(0+.*)/ ) { #Review Author
            $variable{'reviewAuthor'} = &getAscii(&getLengthText($1, 8));
          }

          if ( $firstStr =~ m/0b506572666f726d65644279(0+.*)/ ) { #performedBy
            $variable{'performedByTxt'} = &getAscii(&getLengthText($1, 8));
            $variable{'performedByTxtAscii'} = &getFieldAscii($variable{'performedByTxt'});
          }
        }

        if ( $firstStr =~ m/416c6c4d61696e506572666f726d6572496473(0+.*)?4d61696e506572666f726d6572496473/ ) { # All Main Performer IDs
          my $mainPerform = $1;
          while ( $mainPerform =~ s/(^0+.*?)(0000|$)/$2/) {
            my $curPerformer = &getPerformerByPerformerId(&getLengthText($1, 8));
            $variable{"mainPerformerId"} = $variable{"mainPerformerId"} . "[[" . $curPerformer->{'performerId'} . "|" . $curPerformer->{'name'} . "]]";
            $variable{"mainPerformerAscii"} = $variable{"mainPerformerAscii"} . $curPerformer->{'nameAscii'};
          }

          $variable{'mainPerformerAscii'} = &getFieldAscii($variable{'mainPerformerAscii'});
        }

        if ( $firstStr =~ m/0647656e726573(0+.*)0743726564697473/ ) { # Genres
          my $value = $1;
          $value =~ s/..\K(?=.)/ /sg;

          while ( $value =~ s/(^00 00 00.*?)(00 00 00|$)/$2/) {
            my $mygenre = $1;
            $mygenre =~ s/\s//g;
            $variable{"genres"} = $variable{"genres"} . "[[" . &getAscii(&getLengthText($mygenre, 8)) . "]]";
          }
        } elsif ( $firstStr =~ m/52656c6561736544617465.*?(.{4})0a8295/ ||
                  $firstStr =~ m/52656c6561736544617465.{6}59656172.{4}(.{4})/ ) { # Year
          $variable{'year'} = &convertHexToDec($1);
        } else {
        }

        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isCompilation]]" if ( $firstStr =~ m/860d4973436f6d70696c6174696f6e/ ); # is compilation
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isCastRecording]]" if ( $firstStr =~ m/860f4973436173745265636f7264696e67/ ); # is cast recording
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isLive]]" if ( $firstStr =~ m/860649734c697665/ ); # is Live
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isBootleg]]" if ( $firstStr =~ m/86094973426f6f746c6567/ ); # is bootleg
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isDJMix]]" if ( $firstStr =~ m/86074973444a4d6978/ ); # is DJ Mix
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isKaraoke]]" if ( $firstStr =~ m/860949734b6172616f6b65/ ); # is karaoke
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isBoxSet]]" if ( $firstStr =~ m/86084973426f78536574/ ); # is box set
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isVideo]]" if ( $firstStr =~ m/86074973566964656f/ ); # is Video
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[explicitContent]]" if ( $firstStr =~ m/8617436f6e7461696e734578706c69636974436f6e74656e74/ ); # contain explicit content
        $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isPick]]" if ( $firstStr =~ m/860649735069636b/ ); # is Video
      }

      if ( $variable{'image'} =~ m/^$/ && $firstStr =~ m/(0{6}.{2}68747470(73)?3a2f2f.*)0a46726f6e74436f766572/ ) {
        $variable{'image'} = &getAscii(&getLengthText($1, 8));

        $variable{'image'} =~  m/(\.[^.]+)$/;
        my $filename = "img/" . $variable{'albumId'} . $1;
        &downloadFile( $variable{'image'}, $filename) if ( ! -e $filename );
      }

      if ( $currentField =~ m/^credit$/ ) { #inside Credits
        if ( $firstStr =~ m/81064c6162656c73(0+.*)/ ) { # label, end of credits
          $variable{'label'} = "[[" . &getAscii(&getLengthText($1, 8)) . "]]";
          $currentField = "";
        } else {
          if ( $firstStr =~ m/^.{12}(0{6}.*?)(0{6}.*?)(0{6}.*)/) { # Credits
            (my $personId, $role, $roleType) = ($1, $2, $3);
            $personId = &getLengthText($personId, 8);
            $role = &getAscii(&getLengthText($role, 8));
            $roleType = &getAscii(&getLengthText($roleType, 8));
            $variable{'credit'} = $variable{'credit'} . "[[" . $personId . "|" . $role . "|" . $roleType . "]]";
          }
        }
      }

      if ( $firstStr =~ m/0b506572666f726d65724964(0+.*)/ ) { # First Credit
        if ( $1 =~ m/(0{6}.*?)(0{6}.*?)(0{6}.*)/ ) { #credits
          (my $personId, $role, $roleType) = ($1, $2, $3);
          $personId = &getLengthText($personId, 8);
          $role = &getAscii(&getLengthText($role, 8));
          $roleType = &getAscii(&getLengthText($roleType, 8));

          $variable{'credit'} = $variable{'credit'} . "[[" . $personId . "|" . $role . "|" . $roleType . "]]";
          $currentField = "credit";
        }
      }
    }

    $inSth->execute($variable{'albumId'} ,$variable{'title'}, $variable{'year'},
                    $variable{'isBooleans'} ,$variable{'mainPerformerId'}, $variable{'genres'},
                    $variable{'label'} ,$variable{'reviewText'}, $variable{'credit'},
                    $variable{'reviewAuthor'}, $variable{'country'}, $variable{'catalog'},
                    $variable{'productCode'}, $variable{'metadataAlbumId'}, $variable{'titleAscii'},
                    $variable{'mainPerformerAscii'}, "sooloos", $variable{'performedByTxt'},
                    $variable{'performedByTxtAscii'}, $variable{'image'}, $variable{'altAlbumIds'} );

    # $inSth->execute($variable{'year'}, $variable{'albumId'}, $variable{'reviewText'},
    #                 $variable{'label'}, $variable{'credit'}, $variable{'title'},
    #                 $variable{'reviewAuthor'}, $variable{'genres'}, $variable{'isBooleans'},
    #                 $variable{'mainPerformerId'}, $variable{'titleAscii'}, $variable{'mainPerformerAscii'});

    if ($ctr % 100 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  print "Finished process sooloosAlbum\n";
}

sub retrieveMusicDBAlbum {
  print "STARTING Processing musicDBAlbum\n";

  my $sth = $dbh->prepare( $SELECT_MUSICDB_ALBUM );
  my $inSth = $dbh->prepare( $INSERT_INTO_ROON_ALBUM );
  my $updSth = $dbh->prepare( $UPDATE_ROON_ALBUM_W_MUSICDB );
  #  my $inSth = $dbh->prepare( $INSERT_TO_MUSIDCDBALBUM );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;
    my $curPerformerId;

    my $valueHex = $row->{'valueHex'};

    $valueHex =~ s/..\K(?=.)/ /sg;

    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);
      $firstStr =~ s/\s//g;

      if ( $firstStr =~ m/055469746c65(0+.*)/ ) { # title
        $variable{'title'} = &getAscii(&getLengthText($1, 8));
        $variable{'titleAscii'} = &getFieldAscii($variable{'title'});
      }

      if ( $firstStr =~ m/07436f756e747279(0+.*)/ ) { # country
        $variable{'country'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/064c6162656c73(0+.*?)(0d436174616c6f674e756d626572|0b50726f64756374436f6465|094973426f6f746c6567|0647656e726573)/ ) { # label
        my $listStr = $1;
        $listStr =~ s/..\K(?=.)/ /sg;

        while ( $listStr =~ s/(^00 00 00.*?)(00 00 00|$)/$2/) { # labels
          my $value = $1;
          $value =~ s/\s//g;

          $variable{"label"} = $variable{"label"} . "[[" . &getAscii(&getLengthText($value, 8)) . "]]";
        }
      }

      if ( $firstStr =~ m/0d436174616c6f674e756d626572(0+.*)/ ) { # catalog no
        $variable{'catalog'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0b50726f64756374436f6465(0+.*)/ ) { # product code
        $variable{'productCode'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0647656e726573(0+.*)(094973426f6f746c6567)?/ ) { # genre
        my $listStr = $1;
        $listStr =~ s/..\K(?=.)/ /sg;

        while ( $listStr =~ s/(^00 00 00.*?)(00 00 00|$)/$2/) { # labels
          my $value = $1;
          $value =~ s/\s//g;

          $variable{"genres"} = $variable{"genres"} . "[[" . &getAscii(&getLengthText($value, 8)) . "]]";
        }
      }

      if ( $firstStr =~ m/0444617465.{4}0459656172(.{8})/ ) { # year
        $variable{'year'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/07416c62756d4964(0+.*)/ ) { # album Id
        $variable{'albumId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/0f4d65746164617461416c62756d4964(0+.*)/ ) { # metadata album Id
        $variable{'metadataAlbumId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/104d61696e506572666f726d6572496473(0+.*)/ ) { # main performer id
        my $curPerformer = &getPerformerByPerformerId(&getLengthText($1, 8));
        $variable{"mainPerformerId"} = $variable{"mainPerformerId"} . "[[" . $curPerformer->{'performerId'} . "|" . $curPerformer->{'name'} . "]]";
      }

      if ( $firstStr =~ m/0b506572666f726d65644279(0+.*)/ ) { # performedBy
        $variable{'performedByTxt'} = &getAscii(&getLengthText($1, 8));
        $variable{'performedByTxtAscii'} = &getFieldAscii($variable{'performedByTxt'});
      }

      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isBootleg]]" if ( $firstStr =~ m/86094973426f6f746c6567/ ); # is Bootleg
    }

    if ( $variable{'metadataAlbumId'} =~ m/^$/) {
      my $curPerformer = &getPerformerByPerformerId($curPerformerId);
      my $curPer = &getPerformerNameFromAlsoKnownAs($curPerformer->{'name'});

      if ( $curPer =~ m/^$/ ) {
        $curPer = $curPerformer->{'name'};
      }

      $variable{'mainPerformerAscii'} = $variable{'mainPerformerAscii'} . $curPer;
    } else {
      my $curAlbum = &getAlbumByAlbumId($variable{'metadataAlbumId'});
      my $curPerformer = &getPerformersByMultipleIDs( $variable{'albumId'});
      my $curPer = &getPerformerNameFromAlsoKnownAs($curPerformer);

      if ( $curPer =~ m/^$/ ) {
        $curPer = $curPerformer;
      }

      $variable{'mainPerformerAscii'} = $variable{'mainPerformerAscii'} . $curPer;
    }

    $variable{'mainPerformerAscii'} = &getFieldAscii($variable{'mainPerformerAscii'});

    if ( $variable{'metadataAlbumId'} =~ m/^$/ ) {
      $inSth->execute($variable{'albumId'} ,$variable{'title'}, $variable{'year'},
                      $variable{'isBooleans'} ,$variable{'mainPerformerId'}, $variable{'genres'},
                      $variable{'label'} ,$variable{'reviewText'}, $variable{'credits'},
                      $variable{'reviewAuthor'}, $variable{'country'}, $variable{'catalog'},
                      $variable{'productCode'}, $variable{'metadataAlbumId'}, $variable{'titleAscii'},
                      $variable{'mainPerformerAscii'}, "musicDB", $variable{'performedByTxt'},
                      $variable{'performedByTxtAscii'}, $variable{'image'}, "" );
    } else {
      $updSth->execute( $variable{'country'}, $variable{'catalog'}, $variable{'productCode'},
                        $variable{'albumId'}, "both", $variable{'isBooleans'},
                        $variable{'genres'}, $variable{'year'}, $variable{'performedByTxt'},
                        $variable{'performedByTxtAscii'}, $variable{'metadataAlbumId'} );
    }

    # $inSth->execute($variable{'title'} ,$variable{'country'}, $variable{'label'},
    #                 $variable{'catalog'} ,$variable{'productCode'}, $variable{'genres'},
    #                 $variable{'year'} ,$variable{'albumId'}, $variable{'metadataAlbumId'},
    #                 $variable{'mainPerformerId'}, $variable{'isBooleans'}, $variable{'titleAscii'},
    #                 $variable{'mainPerformerAscii'} );

     if ($ctr % 1000 == 0) {
         $dbh->commit() or die $dbh->errstr;
         print "Counter: $ctr\n";
     }

    $ctr++;
  }

  # my $cleanSth = $dbh->prepare( $CLEANUP_ROON_ALBUM );
  # $cleanSth->execute();
  $dbh->commit() or die $dbh->errstr;

  print "Total Counter: $ctr\n";
  print "FINISHED Processing musicDBAlbum\n";
}

sub getAlbumByAlbumId {
    return &getSingleDBRow( $GET_ROONALBUM_BY_ALBUMID, $_[0]);
}


#--------------------------- TRACK SUBS ------------------------------
sub setupRoonTrack {
  print "START process setupRoonTrack\n";

  my $prevTrack;
  my $ctr = 0;

  my $sth = $dbh->prepare( $GET_ROON_TRACK_BY_ASCII );
  my $crStr = $dbh->prepare( $INSERT_TO_ROONCREDIT );
  my $isBoolStr = $dbh->prepare( $INSERT_TO_ROONISBOOLEAN );
  my $delStr = $dbh->prepare( $DELETE_ROON_TRACK_BY_ID );
  my $updAlbPathStr = $dbh->prepare( $UPDATE_ROON_ALBUM_ADD_PATH );
  my $perfSth = $dbh->prepare( $INSERT_TO_MAINPERFORMER );

  $sth->execute();

  while ($row = $sth->fetchrow_hashref()) {
    my $id = $row->{'id'};
    my $trackId = $row->{'trackId'};
    my $albumId = $row->{'albumId'};
    my $titleAscii = $row->{'titleAscii'};
    my $albumPerformerAscii = $row->{'albumPerformerAscii'};
    my $albumAscii = $row->{'albumAscii'};
    my $source = $row->{'source'};

    if (  $titleAscii eq $prevTrack->{'titleAscii'} &&
          $albumPerformerAscii eq $prevTrack->{'albumPerformerAscii'} &&
          $albumAscii eq $prevTrack->{'albumAscii'} ) {

      # $delStr->execute( $id );
    } elsif ( $source =~ m/sooloos/ ) {
      # $delStr->execute( $id );
    } else {
      my $txt = $row->{'isBooleans'};
      @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

      foreach my $curVal (@ary) {
        chomp($curVal);

        if ($curVal !~ m/^$/) {
          $isBoolStr->execute("track", $trackId, $curVal );
        }
      }

      $txt = $row->{'credits'};
      @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

      foreach my $curVal (@ary) {
        chomp($curVal);

        if ($curVal !~ m/^$/) {
          $curVal =~ m/^(.*?)\|(.*?)\|(.*)$/;
          $crStr->execute( "track", $trackId, $1, $2, $3 );
        }
      }

      $txt = $row->{'trackPerformer'};
      @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

      foreach my $curVal (@ary) {
        chomp($curVal);

        if ($curVal !~ m/^$/) {
          $curVal =~ m/^(.*?)\|(.*?)$/;
          $perfSth->execute( "track", $trackId, $1 );
        }
      }
    }

    my $path = $row->{'path'};
    $path = &getPrevLevelPath($path);
    $updAlbPathStr->execute( $path, $albumId );

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
    $prevTrack = $row;
  }

  $dbh->commit() or die $dbh->errstr;
  print "Finished process setupRoonTrack\n";
}

sub retrieveSooloosTrack {
  print "START process sooloosTrack\n";

  my $sth = $dbh->prepare( $GET_SOOLOS_TRACK );
  my $inSth = $dbh->prepare( $INSERT_TO_ROONTRACK );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;

    my $valueHex = $row->{'valueHex'};

    $valueHex =~ s/..\K(?=.)/ /sg;
    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);
      $firstStr =~ s/\s//g;

  #    &printText($firstStr);

      if ( $currentField =~ m/^credit$/ ) { #inside Credits
        $creditStr = $firstStr;
        $creditStr =~ s/..\K(?=.)/ /sg;

        if ( $creditStr =~ m/^.{18}(00 00 .*?)(00 00 .*?)(00 00 .*)/) { # Credits
          (my $personId, $role, $roleType) = ($1, $2, $3);
          $personId =~ s/\s//g;
          $role =~ s/\s//g;
          $roleType =~ s/\s//g;

          $personId = &getLengthText($personId, 8);
          $role = &getAscii(&getLengthText($role, 8));
          $roleType = &getAscii(&getLengthText($roleType, 8));
          $variable{'credits'} = $variable{'credits'} . "[[" . $personId . "|" . $role . "|" . $roleType . "]]";
        } else {
          $currentField = "";
        }
      }

      if ( $firstStr =~ m/07547261636b4964(00+.*)/ ) { # trackId
        $variable{'trackId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/07416c62756d4964(0+.*)/ ) { # AlbumId
        $variable{'albumId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/0d506572666f726d616e63654964(0+.*)/ ) { # performanceId
        $variable{'performanceId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/0750617274496473(0+.*)/ ) { # partID
        $variable{'partId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/13506572666f726d616e63654c6f636174696f6e(0+.*)/ ) { # performanceLocation
        $variable{'performanceLoc'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0b547261636b4e756d626572(.{8})/ ) { # TrackNumber
        $variable{'trackNumber'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/0b4d656469614e756d626572(.{8})/ ) { # media Number
        $variable{'mediaNumber'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/0a4d65646961436f756e74(.{8})/ ) { # media count
        $variable{'mediaCount'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/12576f726b53657175656e63654e756d626572(.{8})/ ) { # work sequence number
        $variable{'workSeqNum'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/055469746c65(0+.*)/ ) { # title
        $variable{'title'} = &getAscii(&getLengthText($1, 8));

        $variable{'titleAscii'} = &getFieldAscii($variable{'title'});
      }

      if ( $firstStr =~ m/0d4c656e6774685365636f6e6473(.{8})/ ) { # length
        $variable{'length'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/08576f726b4e616d65(0+.*)/ ) { # work name
        $variable{'workName'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/08506172744e616d65(0+.*)/ ) { # part name
        $variable{'partName'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0b53656374696f6e4e616d65(0+.*)/ ) { # section name
        $variable{'sectionName'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0b506572666f726d65724964(0+.*)/ ) { # First Credit
        if ( $1 =~ m/(0{6}.*?)(0{6}.*?)(0{6}.*)/ ) { #credits
          (my $personId, $role, $roleType) = ($1, $2, $3);
          $personId = &getLengthText($personId, 8);
          $role = &getAscii(&getLengthText($role, 8));
          $roleType = &getAscii(&getLengthText($roleType, 8));

          $variable{'credits'} = $variable{'credits'} . "[[" . $personId . "|" . $role . "|" . $roleType . "]]";
          $currentField = "credit";
        }
      }

      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isPick]]" if ( $firstStr =~ m/860649735069636b/ ); # is Pick
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isLive]]" if ( $firstStr =~ m/860649734c697665/ ); # is Live
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isPerformerPick" if ( $firstStr =~ m/860f4973506572666f726d65725069636b/ ); # is performer Pick
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isBonusTrack]]" if ( $firstStr =~ m/860c4973426f6e7573547261636b/ ); # is bonus track
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isRemix]]" if ( $firstStr =~ m/8607497352656d6978/ ); # is remix
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isMultimedia]]" if ( $firstStr =~ m/860c49734d756c74696d65646961/ ); # is Multimedia
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[explicitContent]]" if ( $firstStr =~ m/8617436f6e7461696e734578706c69636974436f6e74656e74/ ); # contain explicit content
    }

    if ( $variable{'albumId'} !~ m/^$/ ) {
        my $album = &getAlbumByAlbumId($variable{'albumId'});

        $variable{'albumAscii'} = $album->{'titleAscii'};
        $variable{'albumPerformerAscii'} = $album->{'mainPerformerAscii'};
        $variable{'albumTitle'} = $album->{'title'};
    }

    $inSth->execute($variable{'trackId'} ,$variable{'title'}, $variable{'albumId'},
                    $variable{'trackNumber'} ,$variable{'mediaNumber'}, $variable{'workName'},
                    $variable{'partName'} ,$variable{'credits'}, $variable{'path'},
                    $variable{'musicDBId'} ,$variable{'year'}, $variable{'albumPerformer'},
                    $variable{'albumTitle'}, $variable{'trackPerformer'}, $variable{'length'},
                    $variable{'mediaCount'}, $variable{'partId'}, $variable{'performanceId'},
                    $variable{'performanceLoc'}, $variable{'sectionName'}, $variable{'workSeqNum'},
                    $variable{'isBooleans'}, $variable{'titleAscii'}, $variable{'performerAscii'},
                    $variable{'albumAscii'}, $variable{'albumPerformerAscii'}, "sooloos" );

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  print "Total Counter: $ctr\n";
  print "FINISHED Processing sooloosTrack\n";
}

sub retrieveMusicDBTrack {
  print "STARTING Processing musicDBTrack\n";

  my $sth = $dbh->prepare( $SELECT_MUSICDB_TRACK );
  my $inSth = $dbh->prepare( $INSERT_TO_ROONTRACK );
  my $updSth = $dbh->prepare( $UPDATE_ROONTRACK_W_MUSICDB );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;

    my $valueHex = $row->{'valueHex'};

    $valueHex =~ s/..\K(?=.)/ /sg;

    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);
      $firstStr =~ s/\s//g;

      if ( $currentField =~ m/^credit$/ ) { #inside Credits
        $creditStr = $firstStr;
        $creditStr =~ s/..\K(?=.)/ /sg;

        if ( $creditStr =~ m/^.{18}(00 00 .*?)(00 00 .*?)(00 00 .*)/) { # Credits
          (my $personId, $role, $roleType) = ($1, $2, $3);
          $personId =~ s/\s//g;
          $role =~ s/\s//g;
          $roleType =~ s/\s//g;

          $personId = &getLengthText($personId, 8);
          $role = &getAscii(&getLengthText($role, 8));
          $roleType = &getAscii(&getLengthText($roleType, 8));
          $variable{'credits'} = $variable{'credits'} . "[[" . $personId . "|" . $role . "|" . $roleType . "]]";
        } else {
          $currentField = "";
        }
      }

      if ( $firstStr =~ m/0f5573657256697369626c6550617468(0+.*)/ ) { # path
        $variable{'path'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/12416c62756d4d61696e506572666f726d6572(0+.*)/ ) { # album Performer
        $variable{'albumPerformer'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/12547261636b4d61696e506572666f726d6572(0+.*)/ ) { # track Performer
        my $performerFound = 0;
        my $trackPerformer = &getAscii(&getLengthText($1, 8));
        $variable{'performerAscii'} = &getFieldAscii($trackPerformer);

        if ( $trackPerformer =~ m/\// ) {
          my @performers = split(/\//, $trackPerformer);

          if ( $#performers > -1 ) {
            foreach my $curPerformer (@performers) {
              chomp($curPerformer);

              my $curDBPerformer = &getPerformerByNameAscii(&getFieldAscii($curPerformer));
              if ( $curDBPerformer->{'performerId'} !~ m/^$/ ) {
                $variable{'trackPerformer'} = $variable{'trackPerformer'} . "[[" . $curDBPerformer->{'performerId'} .
                                              "|" . $curDBPerformer->{'name'} . "]]";
                $performerFound = 1;
              }
            }
          }
        } elsif ( $trackPerformer =~ m/\;/ ) {
          my @performers = split(/\;/, $trackPerformer);
          if ( $#performers > -1 ) {
            foreach my $curPerformer (@performers) {
              chomp($curPerformer);
              my $curDBPerformer = &getPerformerByNameAscii(&getFieldAscii($curPerformer));
              if ( $curDBPerformer->{'performerId'} !~ m/^$/ ) {
                $variable{'trackPerformer'} = $variable{'trackPerformer'} . "[[" . $curDBPerformer->{'performerId'} .
                                              "|" . $curDBPerformer->{'name'} . "]]";
                $performerFound = 1;
              }
            }
          }
        } elsif ( $trackPerformer =~ m/\,/ ) {
          my @performers = split(/\,/, $trackPerformer);
          if ( $#performers > -1 ) {
            foreach my $curPerformer (@performers) {
              chomp($curPerformer);
              my $curDBPerformer = &getPerformerByNameAscii(&getFieldAscii($curPerformer));
              if ( $curDBPerformer->{'performerId'} !~ m/^$/ ) {
                $variable{'trackPerformer'} = $variable{'trackPerformer'} . "[[" . $curDBPerformer->{'performerId'} .
                                              "|" . $curDBPerformer->{'name'} . "]]";
                $performerFound = 1;
              }
            }
          }
        } else {
          my $curDBPerformer = &getPerformerByNameAscii(&getFieldAscii($trackPerformer));
          if ( $curDBPerformer->{'performerId'} !~ m/^$/ ) {
            $variable{'trackPerformer'} = $variable{'trackPerformer'} . "[[" . $curDBPerformer->{'performerId'} .
                                          "|" . $curDBPerformer->{'name'} . "]]";
            $performerFound = 1;
          }
        }

        if ( $performerFound == 0 ) {
          my $curDBPerformer = &getPerformerByNameAscii($variable{'performerAscii'});
          if ( $curDBPerformer->{'performerId'} !~ m/^$/ ) {
            $variable{'trackPerformer'} = $variable{'trackPerformer'} . "[[" . $curDBPerformer->{'performerId'} .
                                          "|" . $curDBPerformer->{'name'} . "]]";
            $performerFound = 1;
          }
        }

        if ( $performerFound == 0 ) {
          $variable{'trackPerformer'} = $variable{'trackPerformer'} . "[[|" . $trackPerformer . "]]";
        }
      }

      if ( $firstStr =~ m/055469746c65(0+.*)/ ) { # title
        $variable{'title'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0b4d656469614e756d626572(.{8})/ ) { # media number
        $variable{'mediaNumber'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/0b547261636b4e756d626572(.{8})/ ) { # track number
        $variable{'trackNumber'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/0444617465.{4}0459656172(.{8})/ ) { # year
        $variable{'year'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/07416c62756d4964(0+.*)/ ) { # album Id
        $variable{'albumId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/07547261636b4964(0+.*)/ ) { # trackId
        $variable{'trackId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/0f4d65746164617461547261636b4964(0+.*)/ ) { # metadata trackId
        $variable{'metadataTrackId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/07576f726b546167(0+.*)/ ) { # workTag
        $variable{'workName'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0750617274546167(0+.*)/ ) { # partTag
        $variable{'partName'} = &getAscii(&getLengthText($1, 8));
      }

      if ( $firstStr =~ m/0b506572666f726d65724964(0+.*)/ ) { # First Credit
        if ( $1 =~ m/(0{6}.*?)(0{6}.*?)(0{6}.*)/ ) { #credits
          (my $personId, $role, $roleType) = ($1, $2, $3);
          $personId = &getLengthText($personId, 8);
          $role = &getAscii(&getLengthText($role, 8));
          $roleType = &getAscii(&getLengthText($roleType, 8));

          $variable{'credits'} = $variable{'credits'} . "|-|" . $personId . "|" . $role . "|" . $roleType;
          $currentField = "credit";
        }
      }

      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isPodcast]]" if ( $firstStr =~ m/86094973506f6463617374/ ); # is Pick
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isRadioBan]]" if ( $firstStr =~ m/860a4973526164696f42616e/ ); # is Pick
      $variable{'isBooleans'} = $variable{'isBooleans'} . "[[isAudioBook]]" if ( $firstStr =~ m/860b4973417564696f426f6f6b/ ); # is Pick

    }

    $variable{'albumAscii'} = &getFieldAscii($variable{'albumTitle'});
    $variable{'titleAscii'} = &getFieldAscii($variable{'title'});
    $variable{'albumPerformerAscii'} = &getFieldAscii($variable{'albumPerformer'});


    if ( $variable{'metadataTrackId'} =~ m/^$/ ) {
      $inSth->execute($variable{'trackId'}, $variable{'title'}, $variable{'albumId'},
                      $variable{'trackNumber'}, $variable{'mediaNumber'}, $variable{'workName'},
                      $variable{'partName'}, $variable{'credits'}, $variable{'path'},
                      $variable{'musicDBId'}, $variable{'year'}, $variable{'albumPerformer'},
                      $variable{'albumTitle'}, $variable{'trackPerformer'}, $variable{'length'},
                      $variable{'mediaCount'}, $variable{'partId'}, $variable{'performanceId'},
                      $variable{'performanceLoc'}, $variable{'sectionName'}, $variable{'workSeqNum'},
                      $variable{'isBooleans'}, $variable{'titleAscii'}, $variable{'performerAscii'},
                      $variable{'albumAscii'}, $variable{'albumPerformerAscii'}, "musicDB" );
    } else {
      $updSth->execute($variable{'path'}, $variable{'trackId'}, $variable{'year'},
                      $variable{'albumPerformer'}, $variable{'albumTitle'}, $variable{'trackPerformer'},
                      # $variable{'title'}, $variable{'titleAscii'}, $variable{'performerAscii'},
                      $variable{'title'}, $variable{'performerAscii'},
                      $variable{'albumAscii'}, $variable{'albumPerformerAscii'}, "both",
                      $variable{'metadataTrackId'} );
    }

     if ($ctr % 1000 == 0) {
         $dbh->commit() or die $dbh->errstr;
         print "Counter: $ctr\n";
     }

    $ctr++;
  }

  print "Total Counter: $ctr\n";
  print "FINISHED Processing musicDBTrack\n";
}

sub getTracksByAlbumId {
  return &getArrayDBRows($GET_ROON_TRACKS_BY_ALBUM_ID, $_[0] );
}


#--------------------------- WORK SUBS ------------------------------
sub setupRoonWork {
  print "START process setupRoonWork\n";

  my $prevTrack;
  my $ctr = 0;

  my $sth = $dbh->prepare( $GET_ROON_WORK );
  my $crStr = $dbh->prepare( $INSERT_TO_ROONCREDIT );
  my $genStr = $dbh->prepare( $INSERT_TO_ROON_GENRE );
  my $partStr = $dbh->prepare( $INSERT_TO_ROON_WORK_PART );
  my $secStr = $dbh->prepare( $INSERT_TO_ROON_WORK_SECTION );

  $sth->execute();

  while ($row = $sth->fetchrow_hashref()) {
    my $workId = $row->{'workId'};

    my $txt = $row->{'composer'};
    my @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ($curVal !~ m/^$/) {
        $curVal =~ m/^(.*?)\|(.*)$/;
        $crStr->execute( "work", $workId, $1, "Composer", "Composer" );
      }
    }

    $txt = $row->{'parts'};
    @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ($curVal !~ m/^$/) {
        my @fields = split(/\|/, $curVal);

        my $sectionId;
        $sectionId = $fields[3] if ($#fields == 3 );
        $partStr->execute( $workId, $fields[0], $fields[1], $fields[2], $sectionId );
      }
    }

    $txt = $row->{'section'};
    @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ($curVal !~ m/^$/) {
        $curVal =~ m/^(.*?)\|(.*?)$/;
        $secStr->execute( $workId, $1, $2 );
      }
    }

    $txt = $row->{'genres'};
    @ary = ($txt =~ m/\[\[(.*?)\]\]/g );

    foreach my $curVal (@ary) {
      chomp($curVal);

      if ( $curVal !~ m/^$/ ) {
        &insertGenre("work", $workId, $curVal);
      }
    }

    if ($ctr % 100 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  $dbh->commit() or die $dbh->errstr;
  print "Finished process setupRoonWork\n";

}

sub retrieveSooloosWork {
  print "START process sooloosWork\n";

  my $sth = $dbh->prepare( $GET_SOOLOOS_WORK );
  my $inSth = $dbh->prepare( $INSERT_TO_SOOLOOSWORK );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;

    my $valueString = $row->{'valueString'};
    my $valueHex = $row->{'valueHex'};

    my $currentField = "";

    $valueHex =~ s/..\K(?=.)/ /sg;

    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);
      $firstStr =~ s/\s//g;

  #&printText($firstStr);

      if ( $currentField =~ m/^partSection$/) {
        if ($firstStr =~ m/^.{12}(0{6}.*?)(0{6}.{2}).*?(0{6}.*?)(0{6}.*)/ ) {
          $variable{'parts'} = $variable{'parts'} . "[[" . &getLengthText($1, 8) . "|" . &convertHexToDec($2) . "|" . &getAscii(&getLengthText($3, 8)) . "|" . &getLengthText($4, 8) . "]]";
        } else {
          $currentField = "";
        }
      }

      if ( $currentField =~ m/^parts$/) {
        if ( $firstStr =~ m/^.{12}(0{6}.*?)(0{6}.{2}).*?(0{6}.*)/ ) {
          $variable{'parts'} = $variable{'parts'} . "[[" . &getLengthText($1, 8) . "|" . &convertHexToDec($2) . "|" . &getAscii(&getLengthText($3, 8)) . "]]";
        } else {
          $currentField = "";
        }
      }

      if ( $currentField =~ m/^Section$/) {
        if ( $firstStr =~ m/^.{12}(0{6}.*?)(0{6}.*)/ ) {
          $variable{'section'} = $variable{'section'} . "[[" . &getLengthText($1, 8) . "|" . &getAscii(&getLengthText($2, 8)) . "]]";
        } else {
          $currentField = "";
        }
      }

      if ( $currentField =~ m/^$/ ) {
        if ( $firstStr =~ m/06576f726b4964(00+.*)/ ) { # workId
          $variable{'workId'} = &getLengthText($1, 8);
        }

        if ( $firstStr =~ m/055469746c65(00+.*)/ ) { # title
          $variable{'title'} = &getAscii(&getLengthText($1, 8));
        }

        if ( $firstStr =~ m/0b436f6d706f736572496473(00+.*)0a436f6d706f7365724964/ ) { # composer IDs
          my $listStr = $1;
          $listStr =~ s/..\K(?=.)/ /sg;

          while ( $listStr =~ s/(^00 00 00.*?)(00 00 00|$)/$2/) {
            my $value = $1;
            $value =~ s/\s//g;
            my $composer = &getPerformerByPerformerId( &getLengthText($value, 8));
            $variable{"composer"} = $variable{"composer"} . "[[" . $composer->{'performerId'} . "|" . $composer->{'name'} . "]]";
          }
        }

        if ( $firstStr =~ m/0647656e726573(00+.*)14436f6d706f736974696f6e537461727444617465/ ) { # genres + periods + forms
          my $listStr = $1;

          if ( $listStr =~ s/04466f726d(00+.*)// ) { # form
            $variable{'form'} = &getAscii(&getLengthText($1, 8));
          }

          if ( $listStr =~ s/06572696f64(00+.*)// ) { # Period
            $variable{'period'} = &getAscii(&getLengthText($1, 8));
          }

          $listStr =~ s/..\K(?=.)/ /sg;
          while ( $listStr =~ s/(^00 00 00.*?)(00 00 00|$)/$2/) { # Genres
            my $value = $1;
            $value =~ s/\s//g;

            $variable{"genres"} = $variable{"genres"} . "[[" . &getAscii(&getLengthText($value, 8)) . "]]";
          }
        }

        if ( $firstStr =~ m/0b4465736372697074696f6e.{6}0454657874(00+.*)/ ) { # Description
          $variable{'description'} = &getAscii(&getLengthText($1, 8));
        }

        if ( $firstStr =~ m/14436f6d706f736974696f6e537461727444617465.{6}59656172(.{8})/ ) { # Composition Year
          $variable{'year'} = &convertHexToDec($1);
        }

        if ( $firstStr =~ m/(055061727473.{4}0650617274496400+.*)/ ) { # Initial Parts
          my $partStr = $1;
  #        &printText($partStr);
          if ( $partStr =~ m/0953656374696f6e4964/ ) {
            $partStr =~ m/^.{6}.*?(0{6}.*?)(0{6}.{2}).*?(0{6}.*?)(0{6}.*)/;
            $variable{'parts'} = $variable{'parts'} . "[[" . &getLengthText($1, 8) . "|" . &convertHexToDec($2) . "|" . &getAscii(&getLengthText($3, 8)) . "|" . &getLengthText($4, 8) . "]]";
            $currentField = "partSection";
          } else {
            $partStr =~ m/^.{6}.*?(0{6}.*?)(0{6}.{2}).*?(0{6}.*)/;
            $variable{'parts'} = $variable{'parts'} . "[[" . &getLengthText($1, 8) . "|" . &convertHexToDec($2) . "|" . &getAscii(&getLengthText($3, 8)) . "]]";
            $currentField = "parts";
          }
        }

        if ( $firstStr =~ m/0853656374696f6e73.*?(0{5}.*?)(0{5}.*)/ ) { # Initial Section
          $variable{'section'} = $variable{'section'} . "[[" . &getLengthText($1, 8) . "|" . &getAscii(&getLengthText($2, 8)) . "]]";
          $currentField = "Section";
        }
      }
    }

    $inSth->execute(  $variable{'workId'} ,$variable{'composer'}, $variable{'title'},
                      $variable{'year'} ,$variable{'parts'}, $variable{'description'},
                      $variable{'section'} ,$variable{'genres'}, $variable{'period'},
                      , $variable{'form'});

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  print "Total Counter: $ctr\n";
  print "FINISHED Processing sooloosWork\n";
}


#--------------------------- PERFORMANCE SUBS ------------------------------
sub retrieveSooloosPerformance {
  print "START process sooloosPerformance\n";

  my $sth = $dbh->prepare( $GET_SOOLOOS_PERFORMANCE );
  my $inSth = $dbh->prepare( $INSERT_TO_SOOLOOSPERFORMANCE );

  $sth->execute();

  my $ctr = 0;

  while ($row = $sth->fetchrow_hashref()) {
    my %variable;

    my $valueString = $row->{'valueString'};
    my $valueHex = $row->{'valueHex'};

    $valueHex =~ s/..\K(?=.)/ /sg;

    my @firstParse = split(/$SPLITTER/, $valueHex);

    foreach my $firstStr (@firstParse) {
      chomp($firstStr);
      $firstStr =~ s/\s//g;

      if ( $firstStr =~ m/0d506572666f726d616e63654964(00+.*)/ ) { # performanceId
        $variable{'performanceId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/06576f726b4964(00+.*)/ ) { # workId
        $variable{'workId'} = &getLengthText($1, 8);
      }

      if ( $firstStr =~ m/0d4c656e6774685365636f6e6473(.{8})/ ) { # length second
        $variable{'lengthSecond'} = &convertHexToDec($1);
      }

      if ( $firstStr =~ m/0a547261636b436f756e74(.{8})/ ) { # Track Count
        $variable{'trackCount'} = &convertHexToDec($1);
      }
    }


    $inSth->execute($variable{'performanceId'} ,$variable{'workId'}, $variable{'trackCount'},
                    $variable{'lengthSecond'});

    if ($ctr % 1000 == 0) {
      $dbh->commit() or die $dbh->errstr;
      print "Counter: $ctr\n";
    }

    $ctr++;
  }

  print "Finished $ctr records\n";
  print "END process sooloosPerformance\n";
}


#--------------------------- MULTI TABLE SUBS ------------------------------
sub insertGenre {
  my $mapTo = $_[0];
  my $mapToId = $_[1];
  my $genre = $_[2];

  my $inSth = $dbh->prepare( $INSERT_TO_ROON_GENRE );
  $inSth->execute($mapTo, $mapToId, $genre );
}


#--------------------------- HELPER SUBS ------------------------------
sub connectDB {
  $dbh = DBI->connect(
    "dbi:SQLite:dbname=$dbFile",
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

sub isAlphanumeric {
  my $toTest = $_[0];
  my $toReturn = 1;

  if ($toTest !~ m/[2-7]./i || $toTest =~ m/7F/i )  {
    $toReturn = 0;
  }

  return $toReturn
}

sub getAscii {
  my $toConvert = $_[0];

  if ( $toConvert !~ m/^$/ ) {
    $toConvert =~ s/([[:xdigit:]]{2})/chr(hex($1))/eg;
  }

  return $toConvert;
}

sub getFieldAscii {
  my $var = $_[0];

  $var =~ s/[^a-zA-Z0-9,\(\)]//g;
  $var = &sortString($var);

  return $var;
}

sub getAsciiOrg {
  my $toConvert = $_[0];
  my $toReturn = "";
  my $curHex;

  for ($i = 0; $i < length($toConvert); $i = $i + 2) {
    $curHex = substr $toConvert, $i, 2;
    if ($curHex !~ m/[2-7]./i || $curHex =~ m/7F/i ) {
      $toReturn = $toReturn . "00";
    } else {
      $toReturn = $toReturn . $curHex;
    }
  }

  $toReturn = pack("H*", $toReturn);
  $toReturn =~ tr/\x09\x0A\x0D\x20-\x7E/@/c;

  return $toReturn;
}

sub convertHexToDec {
  $toConvert = $_[0];

  return hex($toConvert);
}

sub printText {
  my $curText = $_[0];
  my $convertedText = &getAsciiOrg($curText);
  $convertedText =~ s/.\K(?=.)/ /sg;
  print "$curText\n";
  print "$convertedText\n";
}

sub getLengthText {
  my $text = $_[0];
  my $lengthDigit = $_[1];
  my $toReturn;
  my $diff;

  if ( $text !~ m/^$/ ) {
    (my $len) = ($text =~ m/^(.{$lengthDigit})/);
    $len = (&convertHexToDec($len) * 2);
    if ( $len > length($text) - $lengthDigit ) {
      $diff = ($len - length($text) + $lengthDigit);
      $len = length($text) - $lengthDigit;
    }

    if ($text =~ m/.{$lengthDigit}(.{$len})/) {
      $toReturn = $1;

      if ( $diff > 0 ) {
        $toReturn = $toReturn . "@" x $diff;
      }
    } else {
      $toReturn = -1;
    }
  }

  return $toReturn;
}

sub sortString {
  my $str = $_[0];
  return join "", sort split //, $str;
}

sub getSingleDBRow {
  my $stmt = $_[0];
  my $id = $_[1];


  my $sth = $dbh->prepare( $stmt );
  $sth->execute($id);

  return $sth->fetchrow_hashref();
}

sub getArrayDBRows {
  my $stmt = $_[0];
  my $id = $_[1];

  my @toReturn;

  my $sth = $dbh->prepare( $stmt );
  $sth->execute($id);

  while ($row = $sth->fetchrow_hashref()) {
    push(@toReturn, $row);
  }

  return @toReturn;
}

sub getArrayDBRowsTwoFields {
  my $stmt = $_[0];
  my $id = $_[1];
  my $id2 = $_[2];

  my @toReturn;

  my $sth = $dbh->prepare( $stmt );
  $sth->execute($id, $id2);

  while ($row = $sth->fetchrow_hashref()) {
    push(@toReturn, $row);
  }

  return @toReturn;
}

sub printHash {
  my %hash = @_;

  foreach my $keys (keys %hash) {
    chomp($keys);
    print "- $keys: $hash{$keys}\n";
  }
}

sub getPrevLevelPath {
  my $path = $_[0];
  my @paths = split(/\//, $path);

  pop(@paths);

  pop(@paths) if ( $paths[$#paths] =~ m/^cd.+/i);
  pop(@paths) if ( $paths[$#paths] =~ m/^[0-9\-]+$/);

  $path = join("/", @paths);

  return $path;
}

sub processRoonDB {
  my $statement = $_[0];

  my $sth = $dbh->prepare( $statement );
  my $updSth = $dbh->prepare( $UPDATE_ROON_DB );

  $sth->execute();

  my $ctr = 0;
  while ($row = $sth->fetchrow_hashref()) {
    my $id = $row->{'idx'};
    my $keyHex = $row->{'keyHex'};
    my $valueHex = $row->{'valueHex'};

    # my $keyString = &getAscii($keyHex);
    # my $valueString = &getAscii($valueHex);

    my $keyString = &getAsciiOrg($keyHex);
    my $valueString = &getAsciiOrg($valueHex);

    $updSth->execute($keyString, $valueString, $id);

    if (++$ctr % 10000 == 0) {
        # print "- counter: $ctr\n";
        $dbh->commit() or die $dbh->errstr;
    }
  }

  $dbh->commit() or die $dbh->errstr;
}

sub downloadFile {
  # print "downloading\n";
  my $url = $_[0];
  my $file = $_[1];
  my $browser = LWP::UserAgent->new;

  my $response = $browser->get($url, ':content_file' => $file );
}

#--------------------------- TEST SUBS ------------------------------
sub testGetPerformerByPerformerId {
  my $performerId = "7a004d4e30303030373634373032";
  my $performer = &getPerformerByPerformerId($performerId);

  foreach my $key (keys %{$performer}) {
    print "$key: $performer->{$key}\n";
  }
}

sub testGetAlbumByAlbumId {
  my $id = "79004d5730303033323938343639";
  my $obj = &getAlbumByAlbumId($id);

  foreach my $key (keys %{$obj}) {
    print "$key: $obj->{$key}\n";
  }
}

sub testGetPerformerNameFromAlsoKnownAs {
  my $toTest = "Members Of The Wiener Oktett";
  print "$toTest is also known as: " . &getPerformerNameFromAlsoKnownAs($toTest) . "\n";
}
