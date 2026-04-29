--[[
    ██╗     ██╗  ██╗██████╗        ███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
    ██║     ╚██╗██╔╝██╔══██╗       ████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
    ██║      ╚███╔╝ ██████╔╝█████╗ ██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝ 
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗ 
    ███████╗██╔╝ ██╗██║  ██║       ██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    🐺 LXR Mailbox System - Database Updater

    Runs on resource start to ensure all required database tables and columns exist.
    Safe to run multiple times — uses IF NOT EXISTS / ALTER TABLE ... ADD COLUMN IF NOT EXISTS.

    ═══════════════════════════════════════════════════════════════════════════════
    Developer:   iBoss21 / The Lux Empire  |  https://www.wolves.land
    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
    ═══════════════════════════════════════════════════════════════════════════════
]]

-- migrated from server/services/migration.lua to mirror bcc-shops layout

CreateThread(function()
    local seed = os.time()
    if type(GetGameTimer) == 'function' then
        seed = seed + GetGameTimer()
    end
    math.randomseed(seed)

    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_mailboxes` (
            `char_identifier` VARCHAR(255) DEFAULT NULL,
            `mailbox_id` INT(11) NOT NULL AUTO_INCREMENT,
            `postal_code` VARCHAR(10) DEFAULT NULL,
            `first_name` VARCHAR(255) DEFAULT NULL,
            `last_name` VARCHAR(255) DEFAULT NULL,
            PRIMARY KEY (`mailbox_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await("ALTER TABLE `bcc_mailboxes` ADD COLUMN IF NOT EXISTS `postal_code` VARCHAR(10) DEFAULT NULL")
    MySQL.query.await("ALTER TABLE `bcc_mailboxes` ADD COLUMN IF NOT EXISTS `first_name` VARCHAR(255) DEFAULT NULL")
    MySQL.query.await("ALTER TABLE `bcc_mailboxes` ADD COLUMN IF NOT EXISTS `last_name` VARCHAR(255) DEFAULT NULL")
    MySQL.query.await("ALTER TABLE `bcc_mailboxes` ADD COLUMN IF NOT EXISTS `char_identifier` VARCHAR(255) DEFAULT NULL")

    MySQL.query.await([[ 
        CREATE UNIQUE INDEX IF NOT EXISTS `uniq_postal_code` ON `bcc_mailboxes` (`postal_code`);
    ]])

    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_mailbox_messages` (
            `from_char` VARCHAR(255) DEFAULT NULL,
            `to_char` VARCHAR(255) DEFAULT NULL,
            `from_name` VARCHAR(255) NOT NULL,
            `message` TEXT DEFAULT NULL,
            `subject` VARCHAR(255) DEFAULT NULL,
            `location` VARCHAR(255) DEFAULT NULL,
            `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `eta_timestamp` BIGINT(20) DEFAULT NULL,
            `is_read` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await("ALTER TABLE `bcc_mailbox_messages` ADD COLUMN IF NOT EXISTS `is_read` TINYINT(1) NOT NULL DEFAULT 0")
    MySQL.update.await("UPDATE `bcc_mailbox_messages` SET `is_read` = 0 WHERE `is_read` IS NULL")

    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_mailbox_contacts` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `owner_mailbox_id` INT(11) NOT NULL,
            `contact_mailbox_id` INT(11) NOT NULL,
            `contact_alias` VARCHAR(255) DEFAULT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uniq_mailbox_contact` (`owner_mailbox_id`, `contact_mailbox_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await("ALTER TABLE `bcc_mailbox_messages` ADD COLUMN IF NOT EXISTS `mail_category` VARCHAR(32) NOT NULL DEFAULT 'personal'")
    MySQL.query.await("ALTER TABLE `bcc_mailbox_messages` ADD COLUMN IF NOT EXISTS `letterhead_key` VARCHAR(64) DEFAULT NULL")
    MySQL.query.await("ALTER TABLE `bcc_mailbox_messages` ADD COLUMN IF NOT EXISTS `priority` VARCHAR(16) NOT NULL DEFAULT 'normal'")
    MySQL.query.await("ALTER TABLE `bcc_mailbox_messages` ADD COLUMN IF NOT EXISTS `is_official` TINYINT(1) NOT NULL DEFAULT 0")
    MySQL.query.await("ALTER TABLE `bcc_mailbox_messages` ADD COLUMN IF NOT EXISTS `sender_mailbox_id` INT(11) DEFAULT NULL")

    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_mailbox_drafts` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `owner_mailbox_id` INT(11) NOT NULL,
            `recipient_postal` VARCHAR(32) DEFAULT NULL,
            `subject` VARCHAR(255) DEFAULT NULL,
            `message` TEXT,
            `mail_category` VARCHAR(32) NOT NULL DEFAULT 'personal',
            `letterhead_key` VARCHAR(64) DEFAULT NULL,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_drafts_owner` (`owner_mailbox_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[ 
        CREATE TABLE IF NOT EXISTS `bcc_mailbox_audit` (
            `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `action` VARCHAR(32) NOT NULL,
            `source_player` INT(11) DEFAULT NULL,
            `char_identifier` VARCHAR(255) DEFAULT NULL,
            `mailbox_id` INT(11) DEFAULT NULL,
            `target_mailbox_id` INT(11) DEFAULT NULL,
            `detail` VARCHAR(512) DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_audit_created` (`created_at`),
            KEY `idx_audit_char` (`char_identifier`(100))
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[CREATE INDEX IF NOT EXISTS `idx_messages_to_read_id` ON `bcc_mailbox_messages` (`to_char`, `is_read`, `id` DESC)]])
    MySQL.query.await([[CREATE INDEX IF NOT EXISTS `idx_messages_sender_box` ON `bcc_mailbox_messages` (`sender_mailbox_id`, `id` DESC)]])
    MySQL.query.await([[CREATE INDEX IF NOT EXISTS `idx_contacts_owner` ON `bcc_mailbox_contacts` (`owner_mailbox_id`)]])
    MySQL.query.await([[CREATE INDEX IF NOT EXISTS `idx_mailboxes_char` ON `bcc_mailboxes` (`char_identifier`(100))]])

    pcall(function()
        MySQL.update.await([[
            UPDATE bcc_mailbox_messages m
            INNER JOIN bcc_mailboxes b ON UPPER(TRIM(COALESCE(m.from_char, ''))) = UPPER(TRIM(COALESCE(b.postal_code, '')))
            SET m.sender_mailbox_id = b.mailbox_id
            WHERE m.sender_mailbox_id IS NULL
              AND m.from_char IS NOT NULL
              AND TRIM(m.from_char) <> ''
              AND b.postal_code IS NOT NULL
        ]])
    end)
    pcall(function()
        MySQL.update.await([[
            UPDATE bcc_mailbox_messages m
            INNER JOIN bcc_mailboxes b ON m.from_char = CAST(b.mailbox_id AS CHAR)
            SET m.sender_mailbox_id = b.mailbox_id
            WHERE m.sender_mailbox_id IS NULL
              AND m.from_char IS NOT NULL
        ]])
    end)

    local rows = MySQL.query.await("SELECT `mailbox_id` FROM `bcc_mailboxes` WHERE `postal_code` IS NULL OR `postal_code` = ''")
    if rows and #rows > 0 then
        for _, row in ipairs(rows) do
            local code = GenerateUniquePostalCode()
            local ok = pcall(function()
                MySQL.update.await('UPDATE `bcc_mailboxes` SET `postal_code` = ? WHERE `mailbox_id` = ?', { code, row.mailbox_id })
            end)
            if not ok then
                local code2 = GenerateUniquePostalCode()
                MySQL.update.await('UPDATE `bcc_mailboxes` SET `postal_code` = ? WHERE `mailbox_id` = ?', { code2, row.mailbox_id })
            end
        end
    end

    print("Database tables for \x1b[35m\x1b[1m*lxr-mailbox*\x1b[0m created or updated \x1b[32msuccessfully\x1b[0m.")
end)
