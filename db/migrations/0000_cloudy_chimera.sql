CREATE TABLE `audit_logs` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`actor_staff_id` bigint unsigned,
	`action` varchar(100) NOT NULL,
	`entity_type` varchar(80) NOT NULL,
	`entity_id` varchar(80),
	`details` json,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `audit_logs_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `email_logs` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`reservation_id` bigint unsigned,
	`recipient` varchar(320) NOT NULL,
	`email_type` enum('REQUEST_RECEIVED','CONFIRMATION','UPDATED_CONFIRMATION','FRONT_DESK_NOTIFICATION') NOT NULL,
	`snapshot_version` int NOT NULL DEFAULT 0,
	`subject` varchar(500) NOT NULL,
	`body` text NOT NULL,
	`status` enum('QUEUED','SENT','FAILED') NOT NULL DEFAULT 'QUEUED',
	`error` text,
	`sent_at` timestamp,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `email_logs_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `maintenance_blocks` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`room_id` bigint unsigned NOT NULL,
	`start_date` date NOT NULL,
	`end_date` date NOT NULL,
	`reason` varchar(500) NOT NULL,
	`released_at` timestamp,
	`created_by` bigint unsigned,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `maintenance_blocks_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `media` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`storage_key` varchar(512) NOT NULL,
	`variants` json,
	`original_filename` varchar(255) NOT NULL,
	`mime_type` varchar(80) NOT NULL,
	`width` int NOT NULL,
	`height` int NOT NULL,
	`size` int NOT NULL,
	`alt_text` varchar(500) NOT NULL DEFAULT '',
	`caption` varchar(500) NOT NULL DEFAULT '',
	`is_public` boolean NOT NULL DEFAULT false,
	`created_by` bigint unsigned,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `media_id` PRIMARY KEY(`id`),
	CONSTRAINT `media_storage_key_unique` UNIQUE(`storage_key`)
);
--> statement-breakpoint
CREATE TABLE `reservation_guarantees` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`reservation_id` bigint unsigned NOT NULL,
	`status` enum('PENDING','VERIFIED','PREAUTHORIZED','OVERRIDE','NO_GUARANTEE','FAILED') NOT NULL,
	`method` enum('CARD_VERIFIED','PREAUTHORIZED','FRONT_DESK_OVERRIDE','NO_GUARANTEE') NOT NULL,
	`card_brand` varchar(30),
	`card_last4` varchar(4),
	`guarantee_amount` decimal(10,2),
	`verification_date` timestamp,
	`verified_by` bigint unsigned,
	`provider_reference` varchar(255),
	`notes` text,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `reservation_guarantees_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `reservation_guests` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`reservation_id` bigint unsigned NOT NULL,
	`first_name` varchar(100) NOT NULL,
	`last_name` varchar(100) NOT NULL,
	`is_primary` boolean NOT NULL DEFAULT true,
	CONSTRAINT `reservation_guests_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `reservation_price_items` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`reservation_id` bigint unsigned NOT NULL,
	`version` int NOT NULL,
	`item_type` enum('NIGHT','TAX','FEE') NOT NULL,
	`label` varchar(255) NOT NULL,
	`item_date` date,
	`amount` decimal(10,2) NOT NULL,
	`active` boolean NOT NULL DEFAULT true,
	`superseded_by` int,
	`created_by` bigint unsigned,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `reservation_price_items_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `reservation_status_history` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`reservation_id` bigint unsigned NOT NULL,
	`from_status` varchar(40),
	`to_status` varchar(40) NOT NULL,
	`reason` text,
	`changed_by` bigint unsigned,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `reservation_status_history_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `reservations` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`request_number` varchar(40) NOT NULL,
	`idempotency_key` varchar(80),
	`status` enum('REQUESTED','REVIEWING','AWAITING_GUARANTEE','CARD_GUARANTEED','CONFIRMED','CHECKED_IN','CHECKED_OUT','DECLINED','CANCELLED','NO_SHOW') NOT NULL DEFAULT 'REQUESTED',
	`check_in` date NOT NULL,
	`check_out` date NOT NULL,
	`preferred_check_in_time` varchar(20) NOT NULL DEFAULT '2:00 PM',
	`estimated_arrival_time` varchar(20),
	`confirmed_check_in_time` varchar(20),
	`adults` int NOT NULL,
	`children` int NOT NULL DEFAULT 0,
	`infants` int NOT NULL DEFAULT 0,
	`pets` boolean NOT NULL DEFAULT false,
	`pet_count` int,
	`pet_notes` text,
	`pet_fee` decimal(9,2),
	`room_type_id` bigint unsigned NOT NULL,
	`assigned_room_id` bigint unsigned,
	`kitchen_preference` enum('NO_PREFERENCE','PREFER','REQUIRED') NOT NULL DEFAULT 'NO_PREFERENCE',
	`early_check_in_status` enum('NOT_REQUESTED','REQUESTED','APPROVED','NOT_APPROVED') NOT NULL DEFAULT 'NOT_REQUESTED',
	`first_name` varchar(100) NOT NULL,
	`last_name` varchar(100) NOT NULL,
	`phone` varchar(50) NOT NULL,
	`email` varchar(320) NOT NULL,
	`vehicle_type` varchar(40),
	`special_requests` text,
	`internal_notes` text,
	`estimated_subtotal` decimal(10,2) NOT NULL DEFAULT '0',
	`estimated_taxes` decimal(10,2) NOT NULL DEFAULT '0',
	`estimated_total` decimal(10,2) NOT NULL DEFAULT '0',
	`price_snapshot_version` int NOT NULL DEFAULT 0,
	`no_show_charge_status` enum('PENDING','CHARGED','WAIVED','FAILED'),
	`no_show_charged_amount` decimal(10,2),
	`confirmed_at` timestamp,
	`checked_in_at` timestamp,
	`checked_out_at` timestamp,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `reservations_id` PRIMARY KEY(`id`),
	CONSTRAINT `reservations_request_number_unique` UNIQUE(`request_number`),
	CONSTRAINT `reservations_idempotency_key_unique` UNIQUE(`idempotency_key`)
);
--> statement-breakpoint
CREATE TABLE `room_daily_rates` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`room_id` bigint unsigned NOT NULL,
	`rate_date` date NOT NULL,
	`rate` decimal(9,2) NOT NULL,
	`updated_by` bigint unsigned,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `room_daily_rates_id` PRIMARY KEY(`id`),
	CONSTRAINT `room_rate_date_unique` UNIQUE(`room_id`,`rate_date`)
);
--> statement-breakpoint
CREATE TABLE `room_holds` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`reservation_id` bigint unsigned,
	`room_id` bigint unsigned NOT NULL,
	`start_date` date NOT NULL,
	`end_date` date NOT NULL,
	`expires_at` timestamp NOT NULL,
	`released_at` timestamp,
	`release_reason` varchar(255),
	`created_by` bigint unsigned,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `room_holds_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `room_media` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`room_id` bigint unsigned NOT NULL,
	`media_id` bigint unsigned NOT NULL,
	`sort_order` int NOT NULL DEFAULT 0,
	`is_cover` boolean NOT NULL DEFAULT false,
	`is_public` boolean NOT NULL DEFAULT false,
	CONSTRAINT `room_media_id` PRIMARY KEY(`id`),
	CONSTRAINT `room_media_unique` UNIQUE(`room_id`,`media_id`)
);
--> statement-breakpoint
CREATE TABLE `room_night_inventory` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`room_id` bigint unsigned NOT NULL,
	`stay_date` date NOT NULL,
	`source_type` enum('RESERVATION','HOLD','MAINTENANCE') NOT NULL,
	`source_id` int NOT NULL,
	`reservation_id` bigint unsigned,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `room_night_inventory_id` PRIMARY KEY(`id`),
	CONSTRAINT `room_night_unique` UNIQUE(`room_id`,`stay_date`)
);
--> statement-breakpoint
CREATE TABLE `room_type_media` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`room_type_id` bigint unsigned NOT NULL,
	`media_id` bigint unsigned NOT NULL,
	`sort_order` int NOT NULL DEFAULT 0,
	`is_cover` boolean NOT NULL DEFAULT false,
	CONSTRAINT `room_type_media_id` PRIMARY KEY(`id`),
	CONSTRAINT `type_media_unique` UNIQUE(`room_type_id`,`media_id`)
);
--> statement-breakpoint
CREATE TABLE `room_types` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`slug` varchar(80) NOT NULL,
	`name` varchar(120) NOT NULL,
	`bed_description` varchar(180) NOT NULL,
	`description` text NOT NULL,
	`kitchen_copy` varchar(255) NOT NULL,
	`max_occupancy` int NOT NULL,
	`sort_order` int NOT NULL DEFAULT 0,
	`active` boolean NOT NULL DEFAULT true,
	CONSTRAINT `room_types_id` PRIMARY KEY(`id`),
	CONSTRAINT `room_types_slug_unique` UNIQUE(`slug`)
);
--> statement-breakpoint
CREATE TABLE `rooms` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`room_number` int NOT NULL,
	`room_type_id` bigint unsigned NOT NULL,
	`bed_config` varchar(180) NOT NULL,
	`kitchen` boolean NOT NULL DEFAULT false,
	`max_occupancy` int NOT NULL,
	`public` boolean NOT NULL DEFAULT true,
	`active` boolean NOT NULL DEFAULT true,
	`status` enum('AVAILABLE','MAINTENANCE','INTERNAL') NOT NULL DEFAULT 'AVAILABLE',
	`connecting_room` int,
	`notes` text,
	`default_rate` decimal(9,2) NOT NULL DEFAULT '119.00',
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `rooms_id` PRIMARY KEY(`id`),
	CONSTRAINT `rooms_room_number_unique` UNIQUE(`room_number`)
);
--> statement-breakpoint
CREATE TABLE `site_media` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`media_id` bigint unsigned NOT NULL,
	`slot` enum('HERO','GALLERY','EXTERIOR','PARKING','CONTACT') NOT NULL,
	`sort_order` int NOT NULL DEFAULT 0,
	`active` boolean NOT NULL DEFAULT true,
	CONSTRAINT `site_media_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `site_settings` (
	`key` varchar(100) NOT NULL,
	`value` json NOT NULL,
	`updated_by` bigint unsigned,
	`updated_at` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `site_settings_key` PRIMARY KEY(`key`)
);
--> statement-breakpoint
CREATE TABLE `staff_sessions` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`token_hash` varchar(64) NOT NULL,
	`staff_id` bigint unsigned NOT NULL,
	`expires_at` timestamp NOT NULL,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `staff_sessions_id` PRIMARY KEY(`id`),
	CONSTRAINT `staff_sessions_token_hash_unique` UNIQUE(`token_hash`)
);
--> statement-breakpoint
CREATE TABLE `users` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`name` varchar(120) NOT NULL,
	`email` varchar(320) NOT NULL,
	`password_hash` varchar(255) NOT NULL,
	`role` enum('ADMIN','FRONT_DESK') NOT NULL DEFAULT 'FRONT_DESK',
	`active` boolean NOT NULL DEFAULT true,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `users_id` PRIMARY KEY(`id`),
	CONSTRAINT `users_email_unique` UNIQUE(`email`)
);
--> statement-breakpoint
CREATE TABLE `tax_rules` (
	`id` serial AUTO_INCREMENT NOT NULL,
	`name` varchar(120) NOT NULL,
	`enabled` boolean NOT NULL DEFAULT false,
	`rate` decimal(7,4) NOT NULL DEFAULT '0',
	`effective_date` date NOT NULL,
	`end_date` date,
	`applies_to_fees` boolean NOT NULL DEFAULT false,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `tax_rules_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
ALTER TABLE `audit_logs` ADD CONSTRAINT `audit_logs_actor_staff_id_users_id_fk` FOREIGN KEY (`actor_staff_id`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `email_logs` ADD CONSTRAINT `email_logs_reservation_id_reservations_id_fk` FOREIGN KEY (`reservation_id`) REFERENCES `reservations`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `maintenance_blocks` ADD CONSTRAINT `maintenance_blocks_room_id_rooms_id_fk` FOREIGN KEY (`room_id`) REFERENCES `rooms`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `maintenance_blocks` ADD CONSTRAINT `maintenance_blocks_created_by_users_id_fk` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `media` ADD CONSTRAINT `media_created_by_users_id_fk` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservation_guarantees` ADD CONSTRAINT `reservation_guarantees_reservation_id_reservations_id_fk` FOREIGN KEY (`reservation_id`) REFERENCES `reservations`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservation_guarantees` ADD CONSTRAINT `reservation_guarantees_verified_by_users_id_fk` FOREIGN KEY (`verified_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservation_guests` ADD CONSTRAINT `reservation_guests_reservation_id_reservations_id_fk` FOREIGN KEY (`reservation_id`) REFERENCES `reservations`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservation_price_items` ADD CONSTRAINT `reservation_price_items_reservation_id_reservations_id_fk` FOREIGN KEY (`reservation_id`) REFERENCES `reservations`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservation_price_items` ADD CONSTRAINT `reservation_price_items_created_by_users_id_fk` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservation_status_history` ADD CONSTRAINT `reservation_status_history_reservation_id_reservations_id_fk` FOREIGN KEY (`reservation_id`) REFERENCES `reservations`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservation_status_history` ADD CONSTRAINT `reservation_status_history_changed_by_users_id_fk` FOREIGN KEY (`changed_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservations` ADD CONSTRAINT `reservations_room_type_id_room_types_id_fk` FOREIGN KEY (`room_type_id`) REFERENCES `room_types`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `reservations` ADD CONSTRAINT `reservations_assigned_room_id_rooms_id_fk` FOREIGN KEY (`assigned_room_id`) REFERENCES `rooms`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_daily_rates` ADD CONSTRAINT `room_daily_rates_room_id_rooms_id_fk` FOREIGN KEY (`room_id`) REFERENCES `rooms`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_daily_rates` ADD CONSTRAINT `room_daily_rates_updated_by_users_id_fk` FOREIGN KEY (`updated_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_holds` ADD CONSTRAINT `room_holds_reservation_id_reservations_id_fk` FOREIGN KEY (`reservation_id`) REFERENCES `reservations`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_holds` ADD CONSTRAINT `room_holds_room_id_rooms_id_fk` FOREIGN KEY (`room_id`) REFERENCES `rooms`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_holds` ADD CONSTRAINT `room_holds_created_by_users_id_fk` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_media` ADD CONSTRAINT `room_media_room_id_rooms_id_fk` FOREIGN KEY (`room_id`) REFERENCES `rooms`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_media` ADD CONSTRAINT `room_media_media_id_media_id_fk` FOREIGN KEY (`media_id`) REFERENCES `media`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_night_inventory` ADD CONSTRAINT `room_night_inventory_room_id_rooms_id_fk` FOREIGN KEY (`room_id`) REFERENCES `rooms`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_night_inventory` ADD CONSTRAINT `room_night_inventory_reservation_id_reservations_id_fk` FOREIGN KEY (`reservation_id`) REFERENCES `reservations`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_type_media` ADD CONSTRAINT `room_type_media_room_type_id_room_types_id_fk` FOREIGN KEY (`room_type_id`) REFERENCES `room_types`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `room_type_media` ADD CONSTRAINT `room_type_media_media_id_media_id_fk` FOREIGN KEY (`media_id`) REFERENCES `media`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `rooms` ADD CONSTRAINT `rooms_room_type_id_room_types_id_fk` FOREIGN KEY (`room_type_id`) REFERENCES `room_types`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `site_media` ADD CONSTRAINT `site_media_media_id_media_id_fk` FOREIGN KEY (`media_id`) REFERENCES `media`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `site_settings` ADD CONSTRAINT `site_settings_updated_by_users_id_fk` FOREIGN KEY (`updated_by`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE `staff_sessions` ADD CONSTRAINT `staff_sessions_staff_id_users_id_fk` FOREIGN KEY (`staff_id`) REFERENCES `users`(`id`) ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX `audit_time_idx` ON `audit_logs` (`created_at`);--> statement-breakpoint
CREATE INDEX `email_dedup_idx` ON `email_logs` (`reservation_id`,`email_type`,`snapshot_version`,`status`);--> statement-breakpoint
CREATE INDEX `price_version_idx` ON `reservation_price_items` (`reservation_id`,`version`,`active`);--> statement-breakpoint
CREATE INDEX `reservation_dates_idx` ON `reservations` (`assigned_room_id`,`check_in`,`check_out`);--> statement-breakpoint
CREATE INDEX `reservation_status_idx` ON `reservations` (`status`);--> statement-breakpoint
CREATE INDEX `hold_dates_idx` ON `room_holds` (`room_id`,`start_date`,`end_date`);--> statement-breakpoint
CREATE INDEX `inventory_source_idx` ON `room_night_inventory` (`source_type`,`source_id`);--> statement-breakpoint
CREATE INDEX `inventory_reservation_idx` ON `room_night_inventory` (`reservation_id`);--> statement-breakpoint
CREATE INDEX `rooms_type_idx` ON `rooms` (`room_type_id`);