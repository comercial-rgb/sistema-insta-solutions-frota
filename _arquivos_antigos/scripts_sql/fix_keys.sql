UPDATE active_storage_blobs SET `key` = REPLACE(`key`, 'insta-solutions/production/', '') WHERE `key` LIKE 'insta-solutions/production/%';
SELECT COUNT(*) AS total_blobs FROM active_storage_blobs;
