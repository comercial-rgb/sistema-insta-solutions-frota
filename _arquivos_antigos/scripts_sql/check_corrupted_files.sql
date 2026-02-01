-- Identifica arquivos corrompidos (banco diz que tem tamanho mas arquivo físico tem 0 bytes)
SELECT 
    asb.id,
    asb.key,
    asb.filename,
    asb.byte_size as db_size,
    asb.content_type,
    asb.created_at,
    asa.record_type,
    asa.record_id
FROM active_storage_blobs asb
LEFT JOIN active_storage_attachments asa ON asa.blob_id = asb.id
WHERE asb.byte_size > 0
ORDER BY asb.created_at DESC
LIMIT 50;
