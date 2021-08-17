const topUrl = "http://localhost:3002/roonAPI";

// var topUrl = window.location.protocol + "//" + window.location.hostname + ":" + window.location.port;
// var curZone = window.location.search.split('=')[1];


var multiSessionKey = (+new Date).toString(36).slice(-5);

var socket = io();
var curZone = "-";
var zones = {};
var prevStatus = {};

function ajax_get(url, callback) {
    xmlhttp = new XMLHttpRequest();
    xmlhttp.onreadystatechange = function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            try {
                var data = JSON.parse(xmlhttp.responseText);
            } catch(err) {
                return;
            }
            callback(data);
        }
    };

    xmlhttp.open("GET", url, true);
    xmlhttp.send();
}

function getUrl(url) {
  var request = new XMLHttpRequest();
  request.open('GET', url, false);  // `false` makes the request synchronous
  request.send(null);

  if (request.status === 200) {
    return JSON.parse(request.responseText);
  }
}

socket.on('initialzones', function(msg){
  zones = msg;

  prevStatus.playerStatus = "stopped"
  prevStatus.volumeMouseDown = 0;
  prevStatus.seekMouseDown = 0;
  prevStatus.isPlayerVisible = 0;

  setupZoneList();
  updateZoneList(zones);
  updateZone(zones);
});

socket.on('zones', function(msg) {
  zones = msg;

  updateZone(zones);

  prevStatus.curZone = curZone;
  prevStatus.zones = zones;
});


// -------------------------------- SETUPS ----------------------------

function initialSetup() {
  setupBottomRight();
  setupTopLevelLinks();
  clearPlayer();

  listByAlbums();
}

function setupBottomRight() { // for zonelist and volume
  var location = $('.bottomRight');
  location.text("");
  location.append("<div class=\"bottomRight-left\"></div>");
  location.append("<div class=\"bottomRight-right\"></div>");
}

function setupTopLevelLinks() {
  var loc = $('.topLeft');
  loc.text("");

  loc.append("<div id=\"mainListArea\">");

  var mainListArea = $('#mainListArea');
  mainListArea.append("<select id=\"mainList\" onchange=\"mainListSelected()\">");

  var mainList = $('#mainList');
  mainList.text("");
  mainList.append($('<option></option>').val(0).html("Select List Type"));
  mainList.append($('<option></option>').val(1).html("by Artists"));
  mainList.append($('<option></option>').val(2).html("by Albums"));
  mainList.append($('<option></option>').val(3).html("Box Sets"));
}

function setupPlayerController() {
  var location = $('.bottomMid');

  location.text("");
  location.append("<div class=\"transportArea\">");

  var transportArea = $('.transportArea');
  transportArea.append("<div class=\"controllerArea\">");

  var controllerArea = $('.controllerArea');
  controllerArea.append( "<img src=\"img/prev.png\" onmouseUp=\"prevController()\">" );
  controllerArea.append( "<img id=\"playpause\" src=\"img/play.png\" onmouseUp=\"playPauseController()\">" );
  controllerArea.append( "<img src=\"img/next.png\" onmouseUp=\"nextController()\">" );

  location.append("<div class=\"seekArea\">");

  var seekArea = $('.seekArea');
  seekArea.append("<input type=\"range\" class=\"seekSlider\" " +
                  "min=0 max=100 value=0 step=\"1\" " +
                  "onmousedown=\"seekMouseDown()\" onmouseUp=\"seekTo()\"\/>");

  prevStatus.playerControllerStatus = 1;
}

function setupVolume() {
  var loc = $('.bottomRight-right');

  loc.text("");
  loc.append("<div class=\"volumeArea\">");

  var volumeArea = $('.volumeArea');
  volumeArea.append("<input type=\"range\" class=\"volume\" " +
                  "name=\"volumeSLD\" min=0 max=100 value=0 step=\"5\" " +
                  "onmouseUp=\"changeVolume()\" onmousedown=\"volumeMouseDown()\"\/>");

}

function setupNowPlaying() {
  var location = $('.bottomleft');

  location.text("");
  location.append("<div class=\"nowPlayingArea\">");

  var nowPlayingArea = $('.nowPlayingArea');
  nowPlayingArea.append("<div class=\"nowPlayingIcon\">" +
                        "<div class=\"nowPlayingItemIcon\">"); // +

  nowPlayingArea.append("<div class=\"nowPlayingAlbumArtistArea\">" +
                        "<div class=\"nowPlayingTitle\"></div>" +
                        "<div class=\"nowPlayingArtist\"></div>");

  prevStatus.isPlayerVisible = 1;
}

function setupZoneList() {
  var loc = $('.bottomRight-left');
  loc.append("<div id=\"zoneArea\">");

  var zoneArea = $('#zoneArea');
  zoneArea.append("<select id=\"zoneList\" onchange=\"zoneSelected()\">");
}


// ----------------------------- PAGE DETAILS -------------------------

function listBoxSets() {
  var mRight = $('.mainBody');
  mRight.text("");
  mRight.append("<div class=\"gallery\">");

  var gallery = $('.gallery');

  ajax_get(topUrl + '/listBoxSets', function(data) {
    for (var i = 0; i < data["list"].length; i++ ) {
      gallery.append( "<div class=\"galleryItem\">" +
                      "<div class=\"galleryItemIcon\">" +
                      "<img src=\"img/" + data["list"][i].objId + ".jpg\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\" onclick=\"listByBoxsetParent(" +
                      data["list"][i].id + ")\"></div>" +
                      "<div class=\"galleryItemTxt\"><b>" + data["list"][i].album + "</b><br>" +
                      data["list"][i].artist + "</div>" +
                      "</div>");
    }
  });

  mRight.append("</div>");
}

function listByAlbums() {
  ajax_get(topUrl + '/listFirstLevelAlbums', function(data) {
    var mRight = $('.mainBody');
    mRight.text("");
    mRight.append("<div class=\"gallery\">");

    var gallery = $('.gallery');

    for (var i = 0; i < data["list"].length; i++ ) {
      var functionLink;

      if ( data["list"][i].level == "boxset" ) {
        functionLink = "listByBoxsetParent(\"" + data["list"][i].id + "\")";
      } else {
        functionLink = "albumDetail(\"" + data["list"][i].id + "\")";
      }
      gallery.append( "<div class=\"galleryItem\">" +
                      "<div class=\"galleryItemIcon\">" +
                      "<img src=\"" + topUrl + "/getIcon?image_key=" + data["list"][i].image_key + "\" onclick=" + functionLink + "></div>" +
                      "<div class=\"galleryItemTxt\"><b>" + data["list"][i].album + "</b><br>" +
                      data["list"][i].artist + "</div>" +
                      "</div>");
    }

    mRight.append("</div>");
  });
}

function listByArtists() {
  var mRight = $('.mainBody');
  mRight.text("");
  mRight.append("<div class=\"gallery\">");

  var gallery = $('.gallery');

  ajax_get(topUrl + '/listArtists', function(data) {
    for (var i = 0; i < data["list"].length; i++ ) {
      if ( data["list"][i].image_key != null ) {
        gallery.append( "<div class=\"galleryItem\">" +
                        "<div class=\"galleryItemIcon\">" +
                        "<img src=\"" + topUrl + "/getIcon?image_key=" + data["list"][i].image_key +
                        "\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\" onclick=\"artistDetail(" +
                        data["list"][i].id + ")\"></div>" +
                        "<div class=\"galleryItemTxt\"><b>" + data["list"][i].album + "</b><br>" +
                        data["list"][i].artist + "</div>" +
                        "</div>");
      } else {
        gallery.append( "<div class=\"galleryItem\">" +
                        "<div class=\"galleryItemIcon\">" +
                        "<img src=\"img/" + data["list"]["objId"] +
                        ".jpg\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\" onclick=\"artistDetail(" +
                        data["list"][i].id + ")\"></div>" +
                        "<div class=\"galleryItemTxt\"><b>" + data["list"][i].album + "</b><br>" +
                        data["list"][i].artist + "</div>" +
                        "</div>");
      }
    }
  });

  mRight.append("</div>");
}

function listByParent(parentId) {
  var mRight = $('.mainBody');
  mRight.text("");
  mRight.append("<div class=\"gallery\">");

  var gallery = $('.gallery');
  ajax_get(topUrl + '/listByParent?parentId=' + parentId, function(data) {
    for (var i = 0; i < data["list"].length; i++ ) {
      gallery.append( "<div class=\"galleryItem\">" +
                      "<div class=\"galleryItemIcon\">" +
                      "<img src=\"" + topUrl + "/getIcon?image_key=" + data["list"][i].image_key + "\" onclick=\"albumDetail(" + data["list"][i].id + ")\"></div>" +
                      "<div class=\"galleryItemTxt\"><b>" + data["list"][i].album + "</b><br>" +
                      data["list"][i].artist + "</div>" +
                      "</div>");
    }
  });

  mRight.append("</div>");
}

function listByBoxsetParent(parentId) {
  var mRight = $('.mainBody');
  mRight.text("");

  ajax_get(topUrl + '/listByBoxsetParent?parentId=' + parentId, function(data) {
    mRight.append("<div class=\"boxsetDetail\">");

    var boxsetDetail = $('.boxsetDetail');
    boxsetDetail.append("<div class=\"boxsetTop\">");

    var boxsetTop = $('.boxsetTop');

    boxsetTop.append("<div class=\"boxsetIcon\">" +
                    "<div class=\"boxsetItemIcon\">" +
                    "<img src=\"img/" + data.list.boxset[0].id +
                    "\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\"></div></div>");

    boxsetTop.append("<div class=\"boxsetTitleArea\">" +
                    "<div class=\"boxsetTitle\">" + data.list.boxset[0].album + "</div>" +
                    "<div class=\"boxsetArtist\">" +
                    "<a href=\"javascript:artistDetailByPerfId(\'" + data.list.boxset[0].performerId + "\');\">" +
                    data.list.boxset[0].artist + "</a></div>" +
                    "<div class=\"playAlbum\">" +
                    "<button class=\"playqueue\" onclick=\"playQueueBySequence(\'play\', \'boxset\', \'" + data.list.boxset[0].id + "\');\">Play</button>" +
                    "<button class=\"playqueue\" onclick=\"playQueueBySequence(\'queue\', \'boxset\', \'" + data.list.boxset[0].id + "\');\">Queue</button>" +
                    "</div>");

    if ( curZone == "" || curZone == "-") {
      $('.playqueue').attr("disabled", true);
    }

    boxsetDetail.append("<div class=\"gallery\">");

    var gallery = $('.gallery');

    for (var i = 0; i < data.list.albums.length; i++ ) {
      gallery.append( "<div class=\"galleryItem\">" +
                      "<div class=\"galleryItemIcon\">" +
                      "<img src=\"" + topUrl + "/getIcon?image_key=" + data.list.albums[i].image_key +
                      "\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\" onclick=\"albumDetail(" +
                      data.list.albums[i].id + ")\"></div>" +
                      "<div class=\"galleryItemTxt\"><b>" + data.list.albums[i].album + "</b><br>" +
                      data.list.albums[i].artist + "</div>" +
                      "</div>");
    }
  });

  mRight.append("</div>");
}

function artistDetailByPerfId(perfId) {
  perfId = perfId.replace(/\s/g, "");

  ajax_get(topUrl + '/getArtistDetailByPerfId?perfId=' + perfId, function(data) {
    showArtistDetail(data);
  });
}

function artistDetail(apiId) {
  ajax_get(topUrl + '/getArtistDetail?apiId=' + apiId, function(data) {
    showArtistDetail(data);
  });
}

function showArtistDetail(data) {
  var mRight = $('.mainBody');
  mRight.text("");
  mRight.append("<div class=\"artistDetail\">");

  var artistDetail = $('.artistDetail');
  artistDetail.append("<div class=\"artistTop\">");

  var artistTop = $('.artistTop');
  if ( data["list"]["artistDetail"][0]["image_key"] == null ) {
    artistTop.append("<div class=\"artistIcon\">" +
                    "<div class=\"artistItemIcon\">" +
                    "<img src=\"img/" + data["list"]["artistDetail"][0]["performerId"] +
                    ".jpg\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\"></div></div>");
  } else {
    artistTop.append("<div class=\"artistIcon\">" +
                    "<div class=\"artistItemIcon\">" +
                    "<img src=\"" + topUrl + "/getIcon?image_key=" + data["list"]["artistDetail"][0].image_key + "\"></div></div>");
  }

  artistTop.append("<div class=\"artistTitleArea\">" +
                  "<div class=\"artistTitle\">" + data["list"]["artistDetail"][0].name + "</div>" +
                  "<div class=\"playAlbum\">" +
                  "<button class=\"playqueue\" onclick=\"playQueueBySequence(\'play\', \'artist\', \'" + data["list"]["artistDetail"][0].id + "\');\">Play</button>" +
                  "<button class=\"playqueue\" onclick=\"playQueueBySequence(\'queue\', \'artist\', \'" + data["list"]["artistDetail"][0].id + "\');\">Queue</button>" +
                  "</div>");

  if ( curZone == "" || curZone == "-") {
    $('.playqueue').attr("disabled", true);
  }

  artistDetail.append("<div class=\"genres\">");
  var genres = $('.genres');

  for (var i = 0; i < data["list"]["genres"].length; i++ ) {
    genres.append("<div class=\"genreText\">" + data["list"]["genres"][i]["genre"] + "</div>");
  }

  artistDetail.append("<div class=\"artistDescription\">");
  var artistDescription = $('.artistDescription');

  var biography = data["list"]["artistDetail"][0]["biography"];

  if ( biography != null ) {
    biography = biography.replace(/\[\[(.*?)\|(.*?)\]\]/g, "<a id=\"bioLink\" href=\"javascript:bioLink(\'$1\');\">$2</a>");
  }

  artistDescription.append(biography);
  artistDescription.append("<p></p>");
  artistDescription.append(data["list"]["artistDetail"][0]["bioAuthor"]);


  // artistDetail.append("<div class=\"artistAlbums\">");
  // var artistAlbums = $('.artistAlbums');
  // artistAlbums.append("Albums");

  artistDetail.append("<div class=\"artistAlbumArea\">");
  var artistAlbumArea = $('.artistAlbumArea');

  artistAlbumArea.append( "<div class=\"sectionHeading\">Albums</div>");

  artistAlbumArea.append("<div class=\"gallery\">");

  var gallery = $('.gallery');
  for (var i = 0; i < data["list"]["albums"].length; i++ ) {
    var functionLink;

    if ( data["list"]["albums"][i].level == "boxset" ) {
      functionLink = "listByBoxsetParent(\'" + data["list"]["albums"][i].id + "\')";
    } else {
      functionLink = "albumDetail(\'" + data["list"]["albums"][i].id + "\')";
    }

    if ( data["list"]["albums"][i].image_key != null ) {
      gallery.append( "<div class=\"galleryItem\">" +
                      "<div class=\"galleryItemIcon\">" +
                      "<img src=\"" + topUrl + "/getIcon?image_key=" + data["list"]["albums"][i].image_key + "\" onclick=\"" +
                      functionLink + "\"></div>" +
                      "<div class=\"galleryItemTxt\"><b>" + data["list"]["albums"][i]["album"] + "</b></div>" +
                      "</div>");
    } else {
      gallery.append( "<div class=\"galleryItem\">" +
                      "<div class=\"galleryItemIcon\">" +
                      "<img src=\"img/" + data["list"]["albums"][i]["albumId"] +
                      ".jpg\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\" onclick=\"" +
                      functionLink + "\"></div>" +
                      "<div class=\"galleryItemTxt\"><b>" + data["list"]["albums"][i]["album"] + "</b></div>" +
                      "</div>");
    }
  }

  artistDetail.append("<div class=\"artistRelationshipsArea\">");
  var artistRelationshipsArea = $('.artistRelationshipsArea');


  var curRelationship = "";
  var relationShipNo = 0;
  var rGallery = "";

  for (var i = 0; i < data["list"]["relationships"].length; i++ ) {
    if ( curRelationship != data["list"]["relationships"][i]["relationshipType"]) {
      artistRelationshipsArea.append("<div class=\"artistRelationships\" id=\"" + relationShipNo + "\">");

      artistRelationships = $( '#' + relationShipNo + '.artistRelationships');

      artistRelationships.append( "<div class=\"sectionHeading\">" + data["list"]["relationships"][i]["relationshipType"] + "</div>");
      artistRelationships.append("<div class=\"roundGallery\" id=\"" + relationShipNo + "\">");

      var rGallery = $( '#' + relationShipNo + '.roundGallery');
      curRelationship = data["list"]["relationships"][i]["relationshipType"];
      relationShipNo = relationShipNo + 1;
    }

    rGallery.append( "<div class=\"roundGalleryItem\">" +
                    "<div class=\"roundGalleryItemIcon\">" +
                    "<img src=\"img/" + data["list"]["relationships"][i]["otherPerformerId"] +
                    ".jpg\" onerror=\"this.onerror=null; this.src=\'img/default.jpg\'\" onclick=\"artistDetailByPerfId(\'" +
                    data["list"]["relationships"][i]["otherPerformerId"] + "\')\"></div>" +
                    "<div class=\"roundGalleryItemTxt\"><b>" + data["list"]["relationships"][i]["name"] + "</b></div>" +
                    "</div>");
  }

  artistDetail.append("<div class=\"workListArea\">");
  var workListArea = $('.workListArea');
  workListArea.append( "<div class=\"sectionHeading\">Works</div>");


  for (var i = 0; i < data["list"]["works"].length; i++ ) {
    workListArea.append("<div class=\"workText\" onClick=\"getWork(" + data["list"]["works"][i]["workId"] +")\">" + data["list"]["works"][i]["title"] + "</div>");
  }
}

function showAlbumDetail(data) {
  var mRight = $('.mainBody');
  mRight.text("");
  mRight.append("<div class=\"albumDetail\">");

  var albumDetail = $('.albumDetail');
  albumDetail.append("<div class=\"albumTop\">");

  var albumTop = $('.albumTop');

  if ( data["list"]["albumDetail"][0]["image_key"] == null ) {
    albumTop.append("<div class=\"albumIcon\">" +
                    "<div class=\"albumItemIcon\">" +
                    "<img src=\"img/" + data["list"]["albumDetail"][0]["albumId"] + ".jpg\"</div></div>");
  } else {
    albumTop.append("<div class=\"albumIcon\">" +
                    "<div class=\"albumItemIcon\">" +
                    "<img src=\"" + topUrl + "/getIcon?image_key=" + data["list"]["albumDetail"][0].image_key + "\"></div></div>");
  }

  var artistList = "";
  for (var i = 0; i < data["list"]["mainPerformers"].length; i++ ) {

    if ( i > 0 ) {
      artistList = artistList + (" / ");
    }

    artistList = artistList + "<a href=\"javascript:artistDetailByPerfId(\'" + data["list"]["mainPerformers"][i]["performerId"] + "\');\">" +
                    data["list"]["mainPerformers"][i]["name"] + "</a>";
  }

  albumTop.append("<div class=\"albumTitleArea\">" +
                  "<div class=\"albumTitle\">" + data["list"]["albumDetail"][0]["title"] + "</div>" +
                  "<div class=\"albumArtist\">" + artistList + "</div>" +
                  "<div class=\"playAlbum\">" +
                  "<button class=\"playqueue\" onclick=\"playQueueBySequence(\'play\', \'album\', \'" + data["list"]["albumDetail"][0].sequence + "\');\">Play</button>" +
                  "<button class=\"playqueue\" onclick=\"playQueueBySequence(\'queue\', \'album\', \'" + data["list"]["albumDetail"][0].sequence + "\');\">Queue</button>" +
                  "</div>");

  if ( curZone == "" || curZone == "-") {
    $('.playqueue').attr("disabled", true);
  }

  albumDetail.append("<div class=\"genres\">");
  var genres = $('.genres');

  for (var i = 0; i < data["list"]["genres"].length; i++ ) {
    genres.append("<div class=\"genreText\">" + data["list"]["genres"][i]["genre"] + "</div>");
  }

  albumDetail.append("<div class=\"albumReview\">");
  var albumReview = $('.albumReview');
  var reviewText = data["list"]["albumDetail"][0]["reviewText"];

  if ( reviewText != null ) {
    reviewText = reviewText.replace(/\[\[(.*?)\|(.*?)\]\]/g, "<a id=\"bioLink\" href=\"javascript:bioLink(\'$1\');\">$2</a>");
  }

  albumReview.append(reviewText);
  albumReview.append("<p></p>");
  albumReview.append(data["list"]["albumDetail"][0]["reviewAuthor"]);

  if (data["list"]["albumTracks"].length > 0) {
    albumDetail.append("<div class=\"albumTracksArea\">");
    var albumTracksArea = $('.albumTracksArea');

    albumTracksArea.append( "<div class=\"sectionHeading\">Tracks</div>");
    albumTracksArea.append( "<div class=\"albumTracksSection\">");

    var curMediaNumber = 0;
    var curTrackList = "";

    var albumTracksSection = $('.albumTracksSection');

    for (var i = 0; i < data["list"]["albumTracks"].length; i++ ) {
      if ( curMediaNumber != data["list"]["albumTracks"][i]["mediaNumber"]) {
        if ( curMediaNumber > 0 ) {
          curTrackList = curTrackList + "</div>";
          albumTracksSection.append(curTrackList);
          curTrackList = "";
        }

        curTrackList = curTrackList + "<div class=\"albumTracksArea\">";
        curTrackList = curTrackList + "<div class=\"albumTracksDisc\">Disc " +
                            data["list"]["albumTracks"][i]["mediaNumber"] + "</div>";

      }

      curTrackList = curTrackList + "<div class=\"eachTracks\">" +
                          "<div class=\"trackText\">" + data["list"]["albumTracks"][i]["trackNumber"] + "</div>" +
                          "<div class=\"trackText\">" + data["list"]["albumTracks"][i]["title"] + "</div></div>";

      curMediaNumber = data["list"]["albumTracks"][i]["mediaNumber"];
    }

    curTrackList = curTrackList + "</div>";
    albumTracksSection.append(curTrackList);
  }
}

function albumDetail(apiId) {
  ajax_get(topUrl + '/getAlbumDetail?apiId=' + apiId, function(data) {
    showAlbumDetail(data);
  });
}

function albumDetailByAlbumId(albumId) {
  ajax_get(topUrl + '/getAlbumDetailByAlbumId?albumId=' + albumId, function(data) {
    showAlbumDetail(data);
  });
}


// ----------------------------- PAGE UPDATES -------------------------

function updateZone(zone) {
  if ( zone == null || curZone == "-" || zone[curZone] == null ) {
    if ( prevStatus.isPlayerVisible == 1 ) {
      clearPlayer();
    }
  } else {
    if ( zone[curZone] != null ) {
      if ( prevStatus.isPlayerVisible == 0 && zone[curZone].state != "stopped" ) {
        setupPlayerController();
        setupNowPlaying();
        setupVolume();
      }

      if ( zone[curZone].now_playing != null ) {
        if (prevStatus.zones != null && prevStatus.zones[curZone] != null && prevStatus.zones[curZone].now_playing != null ) {
          if ( zone[curZone].now_playing.one_line.line1 != prevStatus.zones[curZone].now_playing.one_line.line1 ) {
            updateNowPlaying(zone[curZone].now_playing);
            updateSeekLength(zone[curZone].now_playing);
          }

          if ( zone[curZone].now_playing.seek_position != prevStatus.zones[curZone].now_playing.seek_position ) {
            updateSeekPosition(zone[curZone].now_playing.seek_position);
          }

          if ( zone[curZone].state != prevStatus.zones[curZone].state ) {
            updatePlayPauseIcon(zone[curZone].state);
          }
        }
      }

      if ( zone[curZone].outputs != null ) {
        if ( zone[curZone].outputs[0].volume == null ) {
          clearVolume();
        } else if ( prevStatus.volumeMouseDown == 0 && prevStatus.zones[curZone].outputs[0].volume != zone[curZone].outputs[0].volume ) {
          updateVolume(zone[curZone].outputs[0].volume);
        }
      } else {
        clearVolume();
      }
    } else {
      clearPlayer();
    }
  }
}

function updateZoneList(zones) {
  var myZone = $('#zoneList');
  myZone.text("");

  ajax_get(topUrl + '/listZones', function(data) {
    myZone.append($('<option></option>').val("-").html("-"));

    for (var i in data["zones"]) {
      myZone.append($('<option></option>').val(data["zones"][i].zone_id).html(data["zones"][i].display_name));
    }
  });
}

function zoneSelected() {
  curZone = $("#zoneList").val();
  prevStatus.playerStatus = "switchZone";

  updateZone(zones);

  if (zones[curZone] != null && zones[curZone].now_playing != null && zones[curZone].now_playing.one_line.line1 != null ) {
    updateNowPlaying(zones[curZone].now_playing);
    updateSeekLength(zones[curZone].now_playing);
    updatePlayPauseIcon(zones[curZone].status);
  } else {
    clearPlayer();
  }

  if ( curZone == "" || curZone == "-") {
    $('.playqueue').attr("disabled", true);
  } else {
    $('.playqueue').attr("disabled", false);
  }
}

function updatePlayPauseIcon(status) {
  var icon = $('#playpause');

  if ( status == "playing") {
    icon.attr("src","img/pause.png");
  } else if ( status == "paused") {
    icon.attr("src","img/play.png");
  }
}

function updateSeekPosition(position) {
  $(".seekSlider").val(position);
}

function updateSeekLength(now_playing) {
  $(".seekSlider").prop({
    min: 0,
    max: now_playing.length
  }).slider();
}

function seekMouseDown() {
  prevStatus.seekMouseDown = 1;
}

function seekTo() {
  var seekNow = $(".seekSlider").val();
  var seekTo = new Object();
  seekTo.seek = seekNow;
  seekTo.outputId = zones[curZone].outputs[0].output_id;

  prevStatus.seekMouseDown = 0;
  socket.emit('seek', JSON.stringify(seekTo));
}

function updateNowPlaying(now_playing) {
  var nowPlayingTitle = $('.nowPlayingTitle');
  nowPlayingTitle.text(now_playing.three_line.line1);

  var nowPlayingArtist = $('.nowPlayingArtist');
  nowPlayingArtist.text(now_playing.three_line.line2);

  var nowPlayingItemIcon = $('.nowPlayingItemIcon');
  nowPlayingItemIcon.html("<img src=\"" + topUrl + "/getIcon?image_key=" + now_playing.image_key  + "\"></div>");
}

function changeVolume() {
  var volume = $(".volume").val();
  var vol = new Object();
  vol.volume = volume;
  vol.outputId = zones[curZone].outputs[0].output_id;

  prevStatus.volumeMouseDown = 0;
  socket.emit('changeVolume', JSON.stringify(vol));
}

function updateVolume(volume) {
  $(".volume").val(volume.value);
}

function volumeMouseDown() {
  prevStatus.volumeMouseDown = 1;
}

function clearPlayer() {
  clearController();
  clearVolume();
  clearNowPlaying();

  prevStatus.isPlayerVisible = 0;
}

function clearVolume() {
  $('.volumeArea').text("");
}

function clearController() {
  $('.bottomMid').text("");
}

function clearNowPlaying() {
  $('.bottomLeft').text("");
}

function prevController() {
  socket.emit('goPrev', curZone);
}

function playPauseController() {
  socket.emit('goPlayPause', curZone);
}

function nextController() {
  socket.emit('goNext', curZone);
}

function playQueueBySequence(type, level, sequence) {
  if ( level == "artist" ) {
    if ( type == "play") {
      socket.emit('playArtist', sequence, multiSessionKey, curZone);
    } else if ( type == "queue" ) {
      socket.emit('queueArtist', sequence, multiSessionKey, curZone);
    }
  } else if ( level == "album" ) {
    if ( type == "play") {
      socket.emit('playAlbum', sequence, multiSessionKey, curZone);
    } else if ( type == "queue" ) {
      socket.emit('queueAlbum', sequence, multiSessionKey, curZone);
    }
  } else if ( level == "boxset" ) {
    if ( type == "play") {
      socket.emit('playBoxSet', sequence, multiSessionKey, curZone);
    } else if ( type == "queue" ) {
      socket.emit('queueBoxSet', sequence, multiSessionKey, curZone);
    }
  }
}

function getLinkObject(linkId, callback) {
  ajax_get(topUrl + '/getObjectLevel?objId=' + linkId, function(data) {
    callback(data);
  });
}

function bioLink(linkId) {
  getLinkObject(linkId, function(data) {
    if ( data["list"] == "performer" ) {
      artistDetailByPerfId(linkId);
    } else if ( data["list"] == "album" ) {
      albumDetailByAlbumId(linkId);
    }

  });
}

function mainListSelected() {
  var curList = $("#mainList").val();

  if ( curList == 1 ) {
    listByArtists();
  } else if ( curList == 2 ) {
    listByAlbums();
  } else if ( curList == 3 ) {
    listBoxSets();
  }

  $("#mainList").val(0);
}
