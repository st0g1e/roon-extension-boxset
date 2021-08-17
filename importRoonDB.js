var level = require('level')
const sqlite3 = require('sqlite3').verbose();

var options = {
  keyEncoding: 'hex',
  valueEncoding: 'hex'
};

var dbLoc = "./RoonDB/broker_2.db"
var roonDB = level(dbLoc, options)
var sqliteDB;


getRoonDB();

function getRoonDB() {
  connectSQLiteDB();

  var ctr = 0;
  sqliteDB.serialize(function() {
    roonDB.createReadStream()
      .on('data', function (data) {

      // console.log("key: " + data.key);
      // console.log("value: " + data.value);
      // console.log("");
      sqliteDB.run(`INSERT INTO roonDB (keyHex, valueHex) VALUES(?, ?)`, [data.key, data.value], function(err) {
        if (err) {
          return console.log("error: ", err.message);
        }
      });

      if ( ctr % 10000 == 0 ) {
        console.log("counter: ", ctr)
      }

      ctr++
    })
    .on('error', function (err) {
      console.log('Oh my!', err)
    })
    .on('close', function () {
      console.log('Stream closed')
    })
    .on('end', function () {
      console.log('Stream ended')
    })
  })

  // disconnectSQLiteDB();
}

function connectSQLiteDB() {
  sqliteDB = new sqlite3.Database('./roonApi/library.sqlite', (err) => {
    if (err) {
      console.error(err.message);
    }

    console.log('Connected to the roon library database.');
  });
}

function disconnectSQLiteDB() {
  sqliteDB.close((err) => {
    if (err) {
      console.error(err.message);
    }

    console.log('Close the database connection.');
  });
}
