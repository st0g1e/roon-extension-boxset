BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "roonDB" (
	"idx"	INTEGER NOT NULL UNIQUE,
	"keyHex"	TEXT,
	"valueHex"	TEXT,
	"keyString"	TEXT,
	"valueString"	TEXT,
	PRIMARY KEY("idx" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonCredit" (
	"id"	INTEGER NOT NULL UNIQUE,
	"mapTo"	TEXT,
	"mapToId"	TEXT,
	"performerId"	TEXT,
	"performerType"	TEXT,
	"performerCategory"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonGenre" (
	"id"	INTEGER NOT NULL UNIQUE,
	"mapTo"	TEXT,
	"mapToId"	TEXT,
	"genre"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonIsBoolean" (
	"id"	INTEGER NOT NULL UNIQUE,
	"mapTo"	TEXT,
	"mapToId"	TEXT,
	"name"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonLabel" (
	"id"	INTEGER NOT NULL UNIQUE,
	"mapTo"	TEXT,
	"mapToId"	TEXT,
	"label"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonPerformance" (
	"id"	INTEGER NOT NULL UNIQUE,
	"performanceId"	TEXT,
	"workId"	TEXT,
	"trackCount"	INTEGER,
	"lengthSecond"	INTEGER,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonPerformerAlsoKnownAs" (
	"id"	INTEGER NOT NULL UNIQUE,
	"performerId"	TEXT,
	"alsoKnownAs"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonPerformerRelationship" (
	"id"	INTEGER NOT NULL UNIQUE,
	"performerId"	TEXT,
	"otherPerformerId"	TEXT,
	"relationshipType"	TEXT,
	"score"	INTEGER,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonTrack" (
	"id"	INTEGER NOT NULL UNIQUE,
	"trackId"	TEXT,
	"title"	TEXT,
	"albumId"	TEXT,
	"trackNumber"	INTEGER,
	"mediaNumber"	INTEGER,
	"workName"	TEXT,
	"partName"	TEXT,
	"credits"	TEXT,
	"path"	TEXT,
	"musicDBId"	TEXT,
	"year"	INTEGER,
	"albumPerformer"	TEXT,
	"albumTitle"	TEXT,
	"trackPerformer"	TEXT,
	"length"	INTEGER,
	"mediaCount"	INTEGER,
	"partId"	TEXT,
	"performanceId"	TEXT,
	"performanceLoc"	TEXT,
	"sectionName"	TEXT,
	"workSeqNum"	INTEGER,
	"isBooleans"	TEXT,
	"titleAscii"	TEXT,
	"performerAscii"	TEXT,
	"albumAscii"	TEXT,
	"albumPerformerAscii"	TEXT,
	"source"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonWork" (
	"id"	INTEGER NOT NULL UNIQUE,
	"workId"	TEXT,
	"composer"	TEXT,
	"title"	TEXT,
	"year"	INTEGER,
	"parts"	TEXT,
	"description"	TEXT,
	"section"	TEXT,
	"genres"	TEXT,
	"period"	TEXT,
	"form"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonWorkPart" (
	"id"	INTEGER NOT NULL UNIQUE,
	"workId"	TEXT,
	"partId"	TEXT,
	"partNo"	INTEGER,
	"title"	TEXT,
	"sectionId"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonWorkSection" (
	"id"	INTEGER NOT NULL UNIQUE,
	"workId"	TEXT,
	"sectionId"	TEXT,
	"title"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonMainPerformers" (
	"id"	INTEGER NOT NULL UNIQUE,
	"mapTo"	TEXT,
	"mapToId"	TEXT,
	"performerId"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonAlbum" (
	"id"	INTEGER NOT NULL UNIQUE,
	"albumId"	TEXT,
	"title"	TEXT,
	"year"	INTEGER,
	"isBooleans"	TEXT,
	"mainPerformerId"	TEXT,
	"genres"	TEXT,
	"label"	TEXT,
	"reviewText"	TEXT,
	"credits"	TEXT,
	"reviewAuthor"	TEXT,
	"country"	TEXT,
	"catalog"	TEXT,
	"productCode"	TEXT,
	"musicDBId"	TEXT,
	"titleAscii"	TEXT,
	"mainPerformerAscii"	TEXT,
	"source"	TEXT,
	"path"	TEXT,
	"imageUrl"	TEXT,
	"performedByTxt"	TEXT,
	"performedByTxtAscii"	TEXT,
	"alternateAlbumIds"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonAlbumAltIDs" (
	"id"	INTEGER NOT NULL UNIQUE,
	"albumId"	TEXT,
	"alternateId"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonPerformer" (
	"id"	INTEGER NOT NULL UNIQUE,
	"performerId"	TEXT,
	"name"	TEXT,
	"type"	TEXT,
	"year"	INTEGER,
	"relationships"	TEXT,
	"biography"	TEXT,
	"bioAuthor"	TEXT,
	"description"	TEXT,
	"imageUrl"	TEXT,
	"birthPlace"	TEXT,
	"genres"	TEXT,
	"country"	TEXT,
	"nameAscii"	TEXT,
	"source"	TEXT,
	"alsoKnownAs"	TEXT,
	"path"	TEXT,
	"altIds"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonPerformerAltIds" (
	"id"	INTEGER NOT NULL UNIQUE,
	"performerId"	TEXT,
	"alternateId"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "roonApis" (
	"id"	integer NOT NULL UNIQUE,
	"parentId"	integer,
	"title"	TEXT(256, 0),
	"subtitle"	TEXT(256, 0),
	"hint"	TEXT(32, 0),
	"image_key"	TEXT(32, 0),
	"sequence"	TEXT(128, 0),
	"level"	TEXT(32, 0),
	"artist"	TEXT(256, 0),
	"album"	TEXT(256, 0),
	"artistsAscii"	TEXT,
	"albumAscii"	TEXT,
	"titleAscii"	TEXT,
	"subtitleAscii"	TEXT,
	"path"	TEXT,
	"performerId"	TEXT,
	"albumId"	TEXT,
	"trackId"	TEXT,
	"albumYear"	INTEGER,
	"objLevel"	INTEGER,
	"boxsetId"	INTEGER,
	PRIMARY KEY("id" AUTOINCREMENT)
);
COMMIT;
