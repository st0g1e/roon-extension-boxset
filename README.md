# roon-extension-boxset

## Box Set folder location.

The extension assumes that box sets are part of an Artist with folder name **Box Sets**

This means that we can have
```
Pink Floyd
  Dark Side of the Moon
  Box Sets
    Pink Floyd - The Early Years
      Pink Floyd - 1965 Their First Recordings
        CD01
        CD02
      Pink Floyd - 1967-1972 Continu-ation
      
Various Artists
  Box Sets
    The Decca Sound - The Analogue Years
      Georg Solti - Chicago Symphony Orchestra
        Georg Solti - Chicago Symphony Orchestra - Bruckner Symphony No. 2
        Georg Solti - Chicago Symphony Orchestra - Stravinsky Le Sacre Du Printemps - Ravel Bolero - Schoenberg Variations
      Oivin Fjeldstad - Clifford Curzon - The London Symphony Orchestra
        Oivin Fjeldstad - Clifford Curzon - The London Symphony Orchestra - Grieg Peer Gynt - Piano Concerto In A Minor
    
```

## Preparation:

```
Copy broker_2.db to roonDB directory
```

## Create sqlite Database

```
>cd roonApi
>touch library.sqlite
>cat createTables.sql | sqlite3 library.sqlite
```

## Install and run roon api extensions

```
>npm install
>node .
```

# Converting roon db

## preparing (in the main directory)
```
>npm install
```

## converting

```
>./importAndProcessData.sh
```

The script above runs three scripts:
1. importRoonDB.js. This imports roon's levelDB data into sqlite
2. processRoonAPIs.pl. This imports data from roon's extension traversing Artists and Albums data. Album traverse is necessary for "Various Artists" artist that is not retrieved from the Artists data.
3. convertRoonDB.pl. This converts the data imported from roon's DB into smaller tables.

# Running the extension
```
go to localhost:3002 on your browser.
```
