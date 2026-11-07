CREATE TABLE IF NOT EXISTS `player_roles` (
  `citizenid` varchar(50) NOT NULL,
  `role` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`citizenid`)
);

INSERT INTO `items` (`name`, `label`, `weight`) VALUES
('military_xp', 'Military XP', 0),
('military_tablet', 'Military Tablet', 1000);