# roon-extension-boxset

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
