CREATE TABLE IF NOT EXISTS `opgarages_garages` (
  `Index` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `Label` varchar(300) DEFAULT NULL,
  `Type` varchar(250) NOT NULL DEFAULT 'car',
  `Coords` varchar(300) NOT NULL DEFAULT '{"CenterOfZone":{"z": 0,"y": 0,"x": 0,"w": 0},"AccessPoint": {"z": 0,"y": 0,"x": 0,"w": 0}}',
  `JobName` varchar(250) DEFAULT NULL,
  `JobGrade` int(11) NOT NULL DEFAULT 0,
  `JobMode` varchar(300) NOT NULL DEFAULT 'owned',
  `Radius` int(11) NOT NULL DEFAULT 20,
  `isPrivate` tinyint(1) NOT NULL DEFAULT 0,
  `privatePlayers` varchar(300) NOT NULL DEFAULT '[]',
  `zpoints` varchar(300) NOT NULL DEFAULT '{"minZ": 0.0, "maxZ": 0.0}',
  `onespawn` varchar(300) NOT NULL DEFAULT '{"z": 0,"y": 0,"x": 0,"w": 0}',
  `GangName` varchar(300) DEFAULT NULL,
  `GangGrade` int(11) DEFAULT 0,
  `GangMode` varchar(300) NOT NULL DEFAULT 'owned',
  `blipDisabled` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`Index`)
);

CREATE TABLE IF NOT EXISTS `opgarages_impounds` (
  `Index` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `Label` varchar(250) DEFAULT NULL,
  `Type` varchar(250) NOT NULL DEFAULT 'car',
  `Coords` varchar(300) NOT NULL DEFAULT '{"z": 0,"y": 0,"x": 0,"w": 0}',
  `AllowedJobs` varchar(300) NOT NULL DEFAULT '[]',
  `blipDisabled` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`Index`)
);

CREATE TABLE IF NOT EXISTS `opgarages_jobvehicles` (
  `index` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `model` VARCHAR(300) DEFAULT NULL,
  `job` VARCHAR(300) DEFAULT NULL,
  `gradesAllowed` VARCHAR(300) NOT NULL DEFAULT '[]',
  `properties` VARCHAR(3000) NOT NULL DEFAULT '{}',
  PRIMARY KEY (`index`)
);

CREATE TABLE IF NOT EXISTS `opgarages_gangvehicles` (
  `index` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `model` varchar(300) DEFAULT NULL,
  `gang` varchar(300) DEFAULT NULL,
  `gradesAllowed` varchar(300) NOT NULL DEFAULT '[]',
  `properties` varchar(3000) NOT NULL DEFAULT '{}',
  PRIMARY KEY (`index`)
);

CREATE TABLE IF NOT EXISTS `opgarages_vehicles` (
  `model` varchar(300) DEFAULT NULL,
  `label` varchar(300) DEFAULT NULL
);