var RoonApi          = require("node-roon-api");
var RoonApiTransport = require("node-roon-api-transport");
var RoonApiStatus    = require("node-roon-api-status");
var RoonApiImage     = require("node-roon-api-image");
var RoonApiSettings  = require('node-roon-api-settings');
var RoonApiBrowse    = require("node-roon-api-browse");

// SERVER CONFIGS
var path = require('path');
var transport;

var express = require('express');
var http = require('http');

var app = express();
var server = http.createServer(app);
const io = require('socket.io')(server);

app.use(express.static(path.join(__dirname, '')));

app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

// DB CONFIGS
const sqlite3 = require('sqlite3').verbose();
var db;

function connectDB() {
  db = new sqlite3.Database('./library.sqlite', sqlite3.OPEN_READONLY, (err) => {
    if (err) {
      console.error(err.message);
    }
    //    console.log('Connected to the roon library database.');
  });
}

function disconnectDB() {
  db.close((err) => {
    if (err) {
      console.error(err.message);
    }
    //    console.log('Close the database connection.');
  });
}


var core;
var zones = [];

var roon = new RoonApi({
   extension_id:        'st0g1e.roon-extension-boxet',
   display_name:        "roon-boxset",
   display_version:     "0.0.1",
   publisher:           'bastian ramelan',
   email:		            'st0g1e@yahoo.com',
   log_level:           'none',

   core_paired: function(core_) {
      core = core_;

	    transport = core_.services.RoonApiTransport;

	    transport.subscribe_zones((response, msg) => {
        if (response == "Subscribed") {
          let curZones = msg.zones.reduce((p,e) => (p[e.zone_id] = e) && p, {});
            zones = curZones;
          } else if (response == "Changed") {
              var z;
              if (msg.zones_removed) msg.zones_removed.forEach(e => delete(zones[e.zone_id]));
              if (msg.zones_added)   msg.zones_added  .forEach(e => zones[e.zone_id] = e);
              if (msg.zones_changed) msg.zones_changed.forEach(e => zones[e.zone_id] = e);
          }

          io.emit("zones", zones);
      });
    },

    core_unpaired: function(core_) {
    }
});

var mysettings = roon.load_config("settings") || {
    webport: "3002",
};

function makelayout(settings) {
    var l = {
      values:    settings,
	    layout:    [],
	    has_error: false
    };

    l.layout.push({
        type:      "string",
        title:     "HTTP Port",
        maxlength: 256,
        setting:   "webport",
    });

    l.layout.push({
        type:      "string",
        title:     "Default Zone",
        maxlength: 256,
        setting:   "defaultZone",
    });

    return l;
}

var svc_settings = new RoonApiSettings(roon, {
    get_settings: function(cb) {
        cb(makelayout(mysettings));
    },
    save_settings: function(req, isdryrun, settings) {
	let l = makelayout(settings.values);
        req.send_complete(l.has_error ? "NotValid" : "Success", { settings: l });

        if (!isdryrun && !l.has_error) {
            var oldport = mysettings.webport;
            mysettings = l.values;
            svc_settings.update_settings(l);
            if (oldport != mysettings.webport) change_web_port(mysettings.webport);
            roon.save_config("settings", mysettings);
        }
    }
});

var svc_status = new RoonApiStatus(roon);

roon.init_services({
   required_services: [ RoonApiTransport, RoonApiImage, RoonApiBrowse ],
   provided_services: [ svc_status, svc_settings ],
});

svc_status.set_status("Extension enabled", false);
roon.start_discovery();

function get_image(image_key, scale, width, height, format) {
   core.services.RoonApiImage.get_image(image_key, {scale, width, height, format}, function(cb, contentType, body) {
      io.emit('image', { image: true, buffer: body.toString('base64') });
   });
};

function change_web_port() {
   server.close();
   server.listen(mysettings.webport, function() {
   console.log('Listening on port: ' + mysettings.webport);
   });
}

server.listen(mysettings.webport, function() {
   console.log('Listening on port: ' + mysettings.webport);
});

// ---------------------------- WEB SOCKET --------------

io.on('connection', function(socket){
//  console.log('a user connected');
  io.emit("initialzones", zones);
  io.emit("defaultZone", mysettings.defaultZone);

  socket.on('disconnect', function(){
//    console.log('user disconnected');
  });

  socket.on('changeVolume', function(msg) {
    var obj = JSON.parse(msg);

    transport.change_volume(obj.outputId, "absolute", obj.volume);
  });

  socket.on('seek', function(msg) {
      var obj = JSON.parse(msg);

      transport.seek(obj.outputId, "absolute", obj.seek);
  });

  socket.on('goPrev', function(msg){
    transport.control(msg, 'previous');
  });

  socket.on('goNext', function(msg){
    transport.control(msg, 'next');
  });

  socket.on('goPlayPause', function(msg){
    transport.control(msg, 'playpause');
  });

  socket.on('goPlay', function(msg){
    transport.control(msg, 'play');
  });

  socket.on('goPause', function(msg){
    transport.control(msg, 'pause');
  });

  socket.on('getImage', function(msg){
     core.services.RoonApiImage.get_image(msg, {"scale": "fit", "width": 300, "height": 200, "format": "image/jpeg"}, function(cb, contentType, body) {
        socket.emit('image', { image: true, buffer: body.toString('base64') });
     });
  });

  socket.on('playAlbum', function( sequence, multiSessionKey, curZone ) {
    playAlbum(sequence, multiSessionKey, curZone);
  });

  socket.on('queueAlbum', function( sequence, multiSessionKey, curZone ) {
    queueAlbum(sequence, multiSessionKey, curZone);
  });

  socket.on('playBoxSet', function( apiId, multiSessionKey, curZone ) {
    playBoxSet(apiId, multiSessionKey, curZone);
  });

  socket.on('queueBoxSet', function( apiId, multiSessionKey, curZone ) {
    queueBoxSet(apiId, multiSessionKey, curZone);
  });

  socket.on('playArtist', function( apiId, multiSessionKey, curZone ) {
    playArtist(apiId, multiSessionKey, curZone);
  });

  socket.on('queueArtist', function( apiId, multiSessionKey, curZone ) {
    queueArtist(apiId, multiSessionKey, curZone);
  });

});


// --------------------- http gets -------------------------

app.get('/', function(req, res){
  res.sendFile(__dirname + '/browser.html');
});

app.get('/roonAPI/listZones', function(req, res) {
  res.send({
    "zones": zones
  })
});

app.get('/roonAPI/getZone', function(req, res) {
   res.send({
    "zone": zones[req.query['zoneId']]
  })
});

app.get('/roonAPI/transfer_zone', function(req, res) {
    core.services.RoonApiTransport.transfer_zone(req.query['fromZoneId'], req.query['toZoneId']);

   res.send({
    "status": "success"
  })
});

app.get('/roonAPI/listOutputs', function(req, res){
    core.services.RoonApiTransport.get_outputs((iserror, body) => {
        if (!iserror) {
            res.send({
                "outputs": body.outputs
            })
        }
    })
});

app.get('/roonAPI/play_pause', function(req, res) {
    core.services.RoonApiTransport.control(req.query['zoneId'], 'playpause');

   res.send({
    "status": "success"
  })
});

app.get('/roonAPI/pause', function(req, res) {
    core.services.RoonApiTransport.control(req.query['zoneId'], 'pause');

   res.send({
    "status": "success"
  })
});

app.get('/roonAPI/play', function(req, res) {
    core.services.RoonApiTransport.control(req.query['zoneId'], 'play');

   res.send({
    "status": "success"
  })
});

app.get('/roonAPI/previous', function(req, res) {
    core.services.RoonApiTransport.control(req.query['zoneId'], 'previous');

    res.send({
       "zone": req.headers.referer
    })
});

app.get('/roonAPI/next', function(req, res) {
  core.services.RoonApiTransport.control(req.query['zoneId'], 'next');

  res.send({
    "zone": core.services.RoonApiTransport.zone_by_zone_id(req.query['zoneId'])
  })
});

app.get('/roonAPI/listSearch', function(req, res) {
   refresh_browse( req.query['zoneId'], { item_key: req.query['item_key'], input: req.query['toSearch'], multi_session_key: req.query['multiSessionKey'] }, 0, 100, function(myList) {
    res.send({
      "list": myList
    })
  });
});

app.get('/roonAPI/listByItemKey', function(req, res) {
   refresh_browse( req.query['zoneId'], { item_key: req.query['item_key'], multi_session_key: req.query['multiSessionKey'] }, 0, 100, function(myList) {

   res.send({
     "list": myList
   })
  });
});

app.get('/roonAPI/listByItemKeyPage', function(req, res) {
   refresh_browse( req.query['zoneId'], { item_key: req.query['item_key'], multi_session_key: req.query['multiSessionKey'] }, req.query['start'], 100, function(myList) {

   res.send({
     "list": myList
   })
  });
});

app.get('/roonAPI/goUp', function(req, res) {
   refresh_browse( req.query['zoneId'], { pop_levels: 1, multi_session_key: req.query['multiSessionKey'] }, 1, 100,  function(myList) {

    res.send({
      "list": myList
    })
  });

});

app.get('/roonAPI/goHome', function(req, res) {
  goHome(req, function(myList) {
    res.send({
     "list": myList
    })
  });
});

app.get('/roonAPI/listRefresh', function(req, res) {
   refresh_browse( req.query['zoneId'], { refresh_list: true, multi_session_key: req.query['multiSessionKey'] }, 0, 0, function(myList) {

   res.send({
     "list": myList
    })
  });
});

app.get('/roonAPI/getIcon', function( req, res ) {
  get_image( req.query['image_key'], "fit", 150, 150, "image/jpeg", res);
});

app.get('/roonAPI/getOriginalImage', function( req, res ) {
  core.services.RoonApiImage.get_image(req.query['image_key'], function(cb, contentType, body) {

     res.contentType = contentType;

     res.writeHead(200, {'Content-Type': 'image/jpeg' });
     res.end(body, 'binary');
  });
});


// --------------- Helper Functions -----------------------

function goHome(req, result) {
  refresh_browse( req.query['zoneId'], { pop_all: true, multi_session_key: req.query['multiSessionKey'] }, 1, 100, function(myList) {
    result(myList);
  });
}

function refresh_browse(zone_id, opts, page, listPerPage, cb) {
    var items = [];
    opts = Object.assign({
        hierarchy:          "browse",
        zone_or_output_id:  zone_id,
    }, opts);


    core.services.RoonApiBrowse.browse(opts, (err, r) => {
        if (err) { console.log(err, r); return; }

        if (r.action == 'list') {
            page = ( page - 1 ) * listPerPage;

            core.services.RoonApiBrowse.load({
                hierarchy:          "browse",
                offset:             page,
                count:              listPerPage,
		            multi_session_key:  opts.multi_session_key,
            }, (err, r) => {
                items = r.items;

                cb(r.items);
            });
        }
    });
}

function get_image(image_key, scale, width, height, format, res) {
   core.services.RoonApiImage.get_image(image_key, {scale, width, height, format}, function(cb, contentType, body) {

      res.contentType = contentType;

      res.writeHead(200, {'Content-Type': 'image/gif' });
      res.end(body, 'binary');
   });
};

// Timers

function playZone(zoneId) {
  core.services.RoonApiTransport.control(zoneId, 'play');
}

function pauseZone(zoneId) {
  refresh_timer();
  core.services.RoonApiTransport.control(zoneId, 'pause');
}

// SQL STATEMENTS
let listFirstLevelAlbumsSql = "SELECT " +
                              "roonApis.id, " +
                              "roonApis.artist, " +
                              "roonApis.album, " +
                              "roonApis.albumId as objId, " +
                              "roonApis.path, " +
                              "roonApis.image_key, " +
                              "roonApis.level, " +
                              "roonApis.sequence " +
                              "from roonApis " +
                              "where " +
                              "roonApis.objLevel = 2 AND " +
                              "roonApis.boxsetId is null " +
                              "group by roonApis.artist, roonApis.album " +
                              "order by " +
                              "roonApis.artist, " +
                              "roonApis.albumYear, " +
                              "roonApis.album";

let listBoxSetsSql =          "SELECT " +
                              "roonApis.id, " +
                              "roonApis.artist, " +
                              "roonApis.album, " +
                              "roonApis.boxsetId, " +
                              "roonApis.albumId as objId, " +
                              "roonApis.path, " +
                              "roonApis.image_key, " +
                              "roonApis.level, " +
                              "roonApis.sequence " +
                              "from roonApis " +
                              "where " +
                              "roonApis.level = 'boxset' " +
                              "group by roonApis.artist, roonApis.album " +
                              "order by " +
                              "roonApis.artist, " +
                              "roonApis.albumYear, " +
                              "roonApis.album";

let listArtistsSql =          "SELECT " +
                              "roonApis.id, " +
                              "roonApis.artist, " +
                              "roonApis.album, " +
                              "roonApis.performerId as objId, " +
                              "roonApis.path, " +
                              "roonApis.image_key, " +
                              "roonApis.level, " +
                              "roonApis.sequence " +
                              "from roonApis " +
                              "where " +
                              "roonApis.objLevel = 1 " +
                              "group by roonApis.artist, roonApis.album " +
                              "order by " +
                              "roonApis.artist, " +
                              "roonApis.albumYear, " +
                              "roonApis.album";

let listByParentSql =         "SELECT " +
                              "roonApis.id, " +
                              "roonApis.artist, " +
                              "roonApis.album, " +
                              "roonApis.albumId as objId, " +
                              "roonApis.path, " +
                              "roonApis.image_key, " +
                              "roonApis.level, " +
                              "roonApis.sequence " +
                              "from roonApis " +
                              "where " +
                              "roonApis.parentId = ? " +
                              "group by roonApis.artist, roonApis.album " +
                              "order by " +
                              "roonApis.artist, " +
                              "roonApis.albumYear, " +
                              "roonApis.album";


let listByBoxsetParentSql =   "SELECT " +
                              "roonApis.id, " +
                              "roonApis.artist, " +
                              "roonApis.album, " +
                              "roonApis.albumId as objId, " +
                              "roonApis.path, " +
                              "roonApis.image_key, " +
                              "roonApis.level, " +
                              "roonApis.sequence " +
                              "from roonApis " +
                              "where " +
                              "roonApis.boxsetId = ? " +
                              "group by roonApis.artist, roonApis.album " +
                              "order by " +
                              "roonApis.artist, " +
                              "roonApis.albumYear, " +
                              "roonApis.album";

let boxsetDetailSql =         "select " +
                              "boxSet.id, " +
                              "boxSet.album, " +
                              "artist.id as artistId, " +
                              "artist.artist, " +
                              "artist.performerId " +
                              "FROM " +
                              "roonApis boxSet, " +
                              "roonApis artist " +
                              "WHERE " +
                              "boxSet.parentId = artist.id " +
                              "and boxSet.id = ? ";

let listAlbumByPerfId =       "SELECT " +
                              "roonApis.id, " +
                              "roonApis.artist, " +
                              "roonApis.album, " +
                              "roonApis.path, " +
                              "roonApis.image_key, " +
                              "roonApis.level, " +
                              "roonApis.sequence " +
                              "from roonApis " +
                              "where " +
                              "roonApis.parentId = " +
	                            "( select distinct roonApis.id " +
                              "from roonApis, roonPerformerAltIds " +
                              "where roonPerformerAltIds.performerId = roonApis.performerId AND " +
                              "roonPerformerAltIds.alternateId = ? ) " +
                              "group by roonApis.artist, roonApis.album " +
                              "order by " +
                              "roonApis.artist, " +
                              "roonApis.albumYear, " +
                              "roonApis.album";

let artistDetailSql =         "select " +
                              "roonApis.id, " +
                              "roonapis.image_key, " +
                              "roonApis.sequence, " +
                              "roonApis.path, " +
                              "roonPerformer.performerId, " +
                              "roonPerformer.name, " +
                              "roonPerformer.biography, " +
                              "roonPerformer.bioAuthor, " +
                              "roonPerformer.description, " +
                              "roonPerformer.type " +
                              "from  " +
                              "roonApis, roonPerformer " +
                              "where " +
                              "roonApis.performerId = roonPerformer.performerId AND " +
                              "roonApis.level = 'artist' AND " +
                              "roonapis.id = ? ";

let artistDetailSqlByPerfId = "select " +
                              "roonPerformer.performerId, " +
                              "roonPerformer.name, " +
                              "roonPerformer.biography, " +
                              "roonPerformer.bioAuthor, " +
                              "roonPerformer.description, " +
                              "roonPerformer.type " +
                              "from  " +
                              "roonPerformer, roonPerformerAltIds " +
                              "where " +
                              "roonPerformer.performerId = roonPerformerAltIds.performerId AND " +
                              "roonPerformerAltIds.alternateId = ? ";

let getRoonApiSql =           "select * from roonApis ";

let listWorkByPerformer =     "select " +
                              "roonCredit.performerId, " +
                              "roonWork.workId, " +
                              "roonWork.year, " +
                              "roonWork.title " +
                              "from roonCredit, roonWork " +
                              "WHERE " +
                              "roonCredit.mapToId = roonWork.workId AND " +
                              "roonCredit.mapTo = 'work' AND " +
                              "roonCredit.performerId = ? " +
                              "order by roonWork.year ";

let artistRelationshipSql =   "select " +
                              "roonPerformerRelationship.otherPerformerId, " +
                              "roonPerformerRelationship.relationshipType, " +
                              "roonPerformerRelationship.score, " +
                              "roonperformer.name " +
                              "from " +
                              "roonPerformerRelationship, roonPerformer " +
                              "where  " +
                              "roonPerformer.performerId = roonPerformerRelationship.otherPerformerId AND " +
                              "roonPerformerRelationship.performerId = ? " +
                              "order By relationshipType, score DESC, name";

let listGenreByIdSql =        "select * " +
                              "from roonGenre " +
                              "where mapToId = ? ";

let albumDetailSql =          "select " +
                              "roonApis.id, " +
                              "roonapis.sequence, " +
                              "roonapis.image_key, " +
                              "roonapis.path, " +
                              "roonapis.level, " +
                              "roonapis.parentId, " +
                              "roonApis.albumId, " +
                              "roonalbum.title, " +
                              "roonAlbum.year, " +
                              "roonAlbum.reviewAuthor, " +
                              "roonAlbum.reviewText " +
                              "from roonApis, roonAlbum " +
                              "where roonApis.albumId = roonAlbum.albumId AND " +
                              "roonApis.id = ? ";

let albumDetailByAlbumIdSql = "select " +
                              "roonApis.id, " +
                              "roonapis.sequence, " +
                              "roonapis.image_key, " +
                              "roonapis.path, " +
                              "roonapis.level, " +
                              "roonapis.parentId, " +
                              "roonApis.albumId, " +
                              "roonalbum.title, " +
                              "roonAlbum.year, " +
                              "roonAlbum.reviewAuthor, " +
                              "roonAlbum.reviewText " +
                              "from roonApis, roonAlbum, roonAlbumAltIDs " +
                              "where roonApis.albumId = roonAlbum.albumId AND " +
                              "roonAlbumAltIDs.albumId = roonAlbum.albumId AND " +
                              "roonAlbumAltIDs.alternateId = ? ";


let albumIsBooleanSql =       "SELECT " +
                              "roonIsBoolean.name " +
                              "from " +
                              "roonIsBoolean " +
                              "WHERE " +
                              "roonIsBoolean.mapToId = ? " +
                              "order by " +
                              "roonIsBoolean.name";

let albumMainPerformerSql =   "select " +
                              "roonMainPerformers.performerId, " +
                              "roonPerformer.name " +
                              "from roonMainPerformers, roonPerformer " +
                              "where " +
                              "roonMainPerformers.performerId = roonPerformer.performerId " +
                              "and roonMainPerformers.mapToId = ? " +
                              "order by roonPerformer.name";

let albumTrackSql =           "select " +
                              "roonApis.id, " +
                              "roonapis.sequence, " +
                              "roonapis.path, " +
                              "roonTrack.mediaNumber, " +
                              "roonTrack.trackNumber, " +
                              "roonTrack.workName, " +
                              "roonTrack.partName, " +
                              "roonTrack.title " +
                              "FROM " +
                              "roonApis, roonTrack " +
                              "WHERE " +
                              "roonApis.trackId = roonTrack.trackId AND " +
                              "roonApis.parentId = ? " +
                              "order by " +
                              "roonApis.id";


// DB FUNCTIONS
function listFirstLevelAlbums(callback) {
  connectDB();

  db.serialize(function() {
    db.all(listFirstLevelAlbumsSql, function(err, allRows) {

      if (err != null) {
        console.log(err);
      }

      callback( allRows );
    });
  });

  disconnectDB();

}

function getPlayAlbumSteps(sequence) {
  var steps = sequence.split("|");
  steps.push("1-0");
  steps.push("1-0");
  steps.push("1-0");
  steps.shift();
  steps.unshift("goHome-100");

  return steps;
}

function getQueueAlbumSteps(sequence) {
  var steps = sequence.split("|");
  steps.push("1-0");
  steps.push("1-2");
  steps.push("1-2");
  steps.shift();
  steps.unshift("goHome-0");

  return steps;
}

function playArtist(apiId, multiSessionKey, curZone) {
  connectDB();

  db.serialize(function() {
    db.all(listByParentSql, [apiId], function(err, allRows) {
      var steps = [];

      for (var i = 0; i < allRows.length; i++ ) {
        if ( i == 0 ) {
          var curStep = getPlayAlbumSteps(allRows[i].sequence);

          for ( var j = 0; j < curStep.length; j++ ) {
            steps.push(curStep[j]);
          }
        } else {
          var curStep = getQueueAlbumSteps(allRows[i].sequence);

          for ( var j = 0; j < curStep.length; j++ ) {
            steps.push(curStep[j]);
          }
        }
      }

      var req = {};
      var res = {};

      req.query = {};
      req.query['zoneId'] = curZone;
      req.query['multiSessionKey'] = multiSessionKey;

      traverseSequence(req, steps, 0);
    });
  });

  disconnectDB();
}

function queueArtist(apiId, multiSessionKey, curZone, result ) {
  connectDB();

  db.serialize(function() {
    db.all(listByParentSql, [apiId], function(err, allRows) {
      var steps = [];

      for (var i = 0; i < allRows.length; i++ ) {
        var curStep = getQueueAlbumSteps(allRows[i].sequence);

        for ( var j = 0; j < curStep.length; j++ ) {
          steps.push(curStep[j]);
        }
      }

      var req = {};
      var res = {};

      req.query = {};
      req.query['zoneId'] = curZone;
      req.query['multiSessionKey'] = multiSessionKey;

      traverseSequence(req, steps, 0);
    });
  });

  disconnectDB();
}

function queueAlbum(sequence, multiSessionKey, curZone) {
  var steps = getQueueAlbumSteps(sequence);

  var req = {};
  var res = {};

  req.query = {};
  req.query['zoneId'] = curZone;
  req.query['multiSessionKey'] = multiSessionKey;

  traverseSequence(req, steps, 0);
}

function playAlbum(sequence, multiSessionKey, curZone ) {
  var steps = getPlayAlbumSteps(sequence);

  var req = {};
  var res = {};

  req.query = {};
  req.query['zoneId'] = curZone;
  req.query['multiSessionKey'] = multiSessionKey;

  traverseSequence(req, steps, 0);
}

function playBoxSet(apiId, multiSessionKey, curZone) {
  connectDB();

  db.serialize(function() {
    db.all(listByBoxsetParentSql, [apiId], function(err, allRows) {
      var steps = [];

      for (var i = 0; i < allRows.length; i++ ) {
        if ( i == 0 ) {
          var curStep = getPlayAlbumSteps(allRows[i].sequence);

          for ( var j = 0; j < curStep.length; j++ ) {
            steps.push(curStep[j]);
          }
        } else {
          var curStep = getQueueAlbumSteps(allRows[i].sequence);

          for ( var j = 0; j < curStep.length; j++ ) {
            steps.push(curStep[j]);
          }
        }
      }

      var req = {};
      var res = {};

      req.query = {};
      req.query['zoneId'] = curZone;
      req.query['multiSessionKey'] = multiSessionKey;

      traverseSequence(req, steps, 0);
    });
  });

  disconnectDB();
}

function queueBoxSet(apiId, multiSessionKey, curZone, result ) {
  connectDB();

  db.serialize(function() {
    db.all(listByBoxsetParentSql, [apiId], function(err, allRows) {
      var steps = [];

      for (var i = 0; i < allRows.length; i++ ) {
        var curStep = getQueueAlbumSteps(allRows[i].sequence);

        for ( var j = 0; j < curStep.length; j++ ) {
          steps.push(curStep[j]);
        }
      }

      var req = {};
      var res = {};

      req.query = {};
      req.query['zoneId'] = curZone;
      req.query['multiSessionKey'] = multiSessionKey;

      traverseSequence(req, steps, 0);
    });
  });

  disconnectDB();
}

function traverseSequence(req, steps, item_key ) {
  if ( steps.length > 0 ) {
    var first = steps.shift();
    var firstStep = first.split("-");
    var page = 0;

    if ( firstStep[0] > 1) {
      page = firstStep[0];
    }

    if ( firstStep[0] == "goHome" ) {
      refresh_browse( req.query['zoneId'], { pop_all: true, multi_session_key: req.query['multiSessionKey'] }, 1, 100, function(myList) {
        traverseSequence(req, steps, myList[0].item_key);
      });
    } else {
      refresh_browse( req.query['zoneId'], { item_key: item_key, multi_session_key: req.query['multiSessionKey'] }, page, 100, function(myList) {
        if (steps.length > 0 ) {
          traverseSequence(req, steps, myList[firstStep[1]].item_key);
        }
      });
    }
  }
}


// DB SELECT CALLS
app.get('/roonAPI/listFirstLevelAlbums', function(req, res) {
  listFirstLevelAlbums(function(data) {
    res.send({
      "list": data
    });
  });
});

app.get('/roonAPI/listBoxsets', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(listBoxSetsSql, function(err, allRows) {

      if (err != null) {
        console.log(err);
      }

      res.send({
        "list": allRows
      })
    });
  });

  disconnectDB();
});

app.get('/roonAPI/listByBoxsetParent', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(listByBoxsetParentSql, [req.query["parentId"]],  function(err, allRows) {

      if (err != null) {
        console.log(err);
      }

      if ( allRows != null && allRows.length > 0 ) {
        db.all(boxsetDetailSql, [req.query["parentId"]],  function(err, boxSet) {

          if (err != null) {
            console.log(err);
          }


          var toReturn = {};
          toReturn.boxset = boxSet;
          toReturn.albums = allRows;

          res.send({
            "list": toReturn
          })
        });
      }

    disconnectDB();
    });
  });
});

app.get('/roonAPI/listArtists', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(listArtistsSql, function(err, allRows) {

      if (err != null) {
        console.log(err);
      }

      res.send({
        "list": allRows
      })
    });
  });

  disconnectDB();
});

app.get('/roonAPI/listByParent', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(listByParentSql, [req.query["parentId"]], function(err, allRows) {

      if (err != null) {
        console.log(err);
      }

      res.send({
        "list": allRows
      })
    });
  });

  disconnectDB();
});

app.get('/roonAPI/getArtistDetail', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(artistDetailSql, [req.query["apiId"]], function(err, perfDetail) {
      if (err != null) {
        console.log(err);
      }

      if ( perfDetail != null && perfDetail.length > 0 ) {
      db.all(listByParentSql, [req.query["apiId"]], function(err, albums) {
        if (err != null) {
          console.log(err);
        }

        db.all(listGenreByIdSql, [perfDetail[0].performerId], function(err, genres) {
          if (err != null) {
            console.log(err);
          }

          db.all(artistRelationshipSql, [perfDetail[0].performerId], function(err, relationship) {
            if (err != null) {
              console.log(err);
            }

            db.all(listWorkByPerformer, [perfDetail[0].performerId], function(err, works) {
              if (err != null) {
                console.log(err);
              }
              var toReturn = {};
              toReturn.artistDetail = perfDetail;
              toReturn.albums = albums;
              toReturn.genres = genres;
              toReturn.relationships = relationship;
              toReturn.works = works;

              res.send({
                "list": toReturn
              })

              disconnectDB();

            });
          });
        });
      });
    } else {
      res.send({
        "list": null
      })
    }
    });
  });
});

app.get('/roonAPI/getArtistDetailByPerfId', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(artistDetailSqlByPerfId, [req.query["perfId"]], function(err, perfDetail) {
      if (err != null) {
        console.log(err);
      }

      if ( perfDetail != null && perfDetail.length > 0 ) {
        db.all(listGenreByIdSql, [perfDetail[0].performerId], function(err, genres) {
          if (err != null) {
            console.log(err);
          }

          db.all(artistRelationshipSql, [perfDetail[0].performerId], function(err, relationship) {
            if (err != null) {
              console.log(err);
            }

            db.all(listWorkByPerformer, [perfDetail[0].performerId], function(err, works) {
              if (err != null) {
                console.log(err);
              }

              db.all(listAlbumByPerfId, [perfDetail[0].performerId], function(err, albums) {
                if (err != null) {
                  console.log(err);
                }

                var toReturn = {};
                toReturn.artistDetail = perfDetail;
                toReturn.albums = albums;
                toReturn.genres = genres;
                toReturn.relationships = relationship;
                toReturn.works = works;

                res.send({
                  "list": toReturn
                })

                disconnectDB();

              });
            });
          });
        });
      } else {
        res.send({
          "list": null
        })
      }
    });
  });
});

app.get('/roonAPI/getAlbumDetail', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(albumDetailSql, [req.query["apiId"]], function(err, albumDetail) {
      if (err != null) {
        console.log(err);
      }

      if ( albumDetail != null && albumDetail.length > 0 ) {
        db.all(albumIsBooleanSql, [albumDetail[0].albumId], function(err, isBoolean) {
          if (err != null) {
            console.log(err);
          }

          db.all(albumMainPerformerSql, [albumDetail[0].albumId], function(err, mainPerformers) {
            if (err != null) {
              console.log(err);
            }

            db.all(listGenreByIdSql, [albumDetail[0].albumId], function(err, genres) {
              if (err != null) {
                console.log(err);
              }

              db.all(albumTrackSql, [albumDetail[0].id], function(err, albumTracks) {
                if (err != null) {
                  console.log(err);
                }
                var toReturn = {};
                toReturn.albumDetail = albumDetail;
                toReturn.isBoolean = isBoolean;
                toReturn.mainPerformers = mainPerformers;
                toReturn.genres = genres;
                toReturn.albumTracks = albumTracks;

                res.send({
                  "list": toReturn
                })

                disconnectDB();
              });
            });
          });
        });
      } else {
        res.send({
          "list": null
        })
      }
    });
  });
});

app.get('/roonAPI/getAlbumDetailByAlbumId', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all(albumDetailByAlbumIdSql, [req.query["albumId"]], function(err, albumDetail) {
      if (err != null) {
        console.log(err);
      }

      if ( albumDetail != null && albumDetail.length > 0 ) {
        db.all(albumIsBooleanSql, [albumDetail[0].albumId], function(err, isBoolean) {
          if (err != null) {
            console.log(err);
          }

          db.all(albumMainPerformerSql, [albumDetail[0].albumId], function(err, mainPerformers) {
            if (err != null) {
              console.log(err);
            }

            db.all(listGenreByIdSql, [albumDetail[0].albumId], function(err, genres) {
              if (err != null) {
                console.log(err);
              }

              db.all(albumTrackSql, [albumDetail[0].id], function(err, albumTracks) {
                if (err != null) {
                  console.log(err);
                }
                var toReturn = {};
                toReturn.albumDetail = albumDetail;
                toReturn.isBoolean = isBoolean;
                toReturn.mainPerformers = mainPerformers;
                toReturn.genres = genres;
                toReturn.albumTracks = albumTracks;

                res.send({
                  "list": toReturn
                })

                disconnectDB();
              });
            });
          });
        });
      } else {
        res.send({
          "list": null
        })
      }
    });
  });
});

app.get('/roonAPI/getObjectLevel', function(req, res) {
  connectDB();

  db.serialize(function() {
    db.all("select id from roonPerformerAltIds where alternateId = ? ", [req.query["objId"]], function(err, perfId) {

      if (err != null) {
        console.log(err);
      }

      if ( perfId != null && perfId.length > 0 ) {
        res.send({
          "list": "performer"
        })

        disconnectDB();
      } else {
        db.all("select id from roonAlbumAltIDs where alternateId = ? ", [req.query["objId"]], function(err, albID) {

          if (err != null) {
            console.log(err);
          }

          if ( albID != null && albID.length > 0 ) {
            res.send({
              "list": "album"
            })

            disconnectDB();
          } else {
            db.all("select id from roonWork where workId=?", [req.query["objId"]], function(err, workId) {

              if (err != null) {
                console.log(err);
              }

              if ( workId != null && workId.length > 0 ) {
                res.send({
                  "list": "work"
                })
              } else {
                res.send({
                  "list": null
                })
              }
            });

            disconnectDB();
          }
        });
      }
    });
  });
});
