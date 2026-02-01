#!/bin/bash
# Script para configurar credenciais AWS S3 no servidor de produção

echo "=== CONFIGURAÇÃO AWS S3 PARA ACTIVE STORAGE ==="
echo ""
echo "⚠️ IMPORTANTE: Você precisa fornecer as credenciais AWS reais!"
echo ""
echo "Passos necessários:"
echo ""
echo "1. Criar/Verificar Bucket S3 na AWS:"
echo "   - Nome sugerido: frotainstasolutions-storage"
echo "   - Região: sa-east-1 (São Paulo)"
echo "   - ACL desabilitado (recomendado)"
echo "   - Block Public Access: Desabilitado (para permitir acesso via URL)"
echo "   - CORS configurado para permitir uploads"
echo ""
echo "2. Criar usuário IAM com permissões S3:"
echo "   - Policy necessária: AmazonS3FullAccess (ou custom com PutObject, GetObject, DeleteObject)"
echo "   - Gerar Access Key ID e Secret Access Key"
echo ""
echo "3. Editar application.yml no servidor:"
echo ""
read -p "Deseja que eu abra o arquivo para edição? (s/n): " RESPOSTA

if [ "$RESPOSTA" = "s" ] || [ "$RESPOSTA" = "S" ]; then
    echo ""
    echo "Editando application.yml..."
    echo ""
    
    nano /var/www/frotainstasolutions/production/config/application.yml
    
    echo ""
    echo "✓ Arquivo editado!"
    echo ""
    echo "Certifique-se de que as seguintes variáveis estão configuradas:"
    echo "  AWS_ACCESS_KEY_ID: \"sua_access_key_real\""
    echo "  AWS_SECRET_ACCESS_KEY: \"sua_secret_key_real\""
    echo "  AWS_REGION: \"sa-east-1\""
    echo "  AWS_BUCKET: \"nome-do-bucket-s3\""
    echo ""
    
    read -p "Deseja reiniciar o servidor agora? (s/n): " RESTART
    
    if [ "$RESTART" = "s" ] || [ "$RESTART" = "S" ]; then
        echo ""
        echo "Reiniciando servidor..."
        sudo systemctl restart frotainstasolutions
        sleep 5
        sudo systemctl status frotainstasolutions --no-pager
        echo ""
        echo "✓ Servidor reiniciado!"
    fi
else
    echo ""
    echo "Para editar manualmente:"
    echo "  nano /var/www/frotainstasolutions/production/config/application.yml"
    echo ""
    echo "Substitua as linhas:"
    echo "  AWS_ACCESS_KEY_ID: \"FAKE_LOCAL_KEY\""
    echo "  AWS_SECRET_ACCESS_KEY: \"FAKE_LOCAL_SECRET\""
    echo "  AWS_BUCKET: \"local-storage\""
    echo ""
    echo "Por:"
    echo "  AWS_ACCESS_KEY_ID: \"AKIAIOSFODNN7EXAMPLE\"  # Sua chave real"
    echo "  AWS_SECRET_ACCESS_KEY: \"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY\"  # Sua chave real"
    echo "  AWS_BUCKET: \"frotainstasolutions-storage\"  # Nome do seu bucket"
    echo ""
    echo "Depois execute:"
    echo "  sudo systemctl restart frotainstasolutions"
fi

echo ""
echo "=== CONFIGURAÇÃO CORS DO BUCKET S3 ==="
echo ""
echo "No console AWS S3, adicione a seguinte configuração CORS:"
echo ""
cat << 'EOF'
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
        "AllowedOrigins": [
            "https://app.frotainstasolutions.com.br",
            "http://app.frotainstasolutions.com.br",
            "http://localhost:3000"
        ],
        "ExposeHeaders": ["ETag"],
        "MaxAgeSeconds": 3000
    }
]
EOF

echo ""
echo "=== POLÍTICA DO BUCKET (Bucket Policy) ==="
echo ""
echo "Para permitir acesso público de leitura aos arquivos:"
echo ""
cat << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::SEU-BUCKET-NAME/*"
        }
    ]
}
EOF

echo ""
echo "Substitua SEU-BUCKET-NAME pelo nome real do bucket!"
echo ""
echo "=== FIM DAS INSTRUÇÕES ==="
