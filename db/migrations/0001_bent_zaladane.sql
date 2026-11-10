CREATE TABLE `rate_limits` (
	`key_hash` varchar(64) NOT NULL,
	`count` int NOT NULL DEFAULT 1,
	`reset_at` timestamp NOT NULL,
	CONSTRAINT `rate_limits_key_hash` PRIMARY KEY(`key_hash`)
);
