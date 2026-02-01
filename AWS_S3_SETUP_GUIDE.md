# CONFIGURAÇÃO AWS S3 PARA ARMAZENAMENTO DE ARQUIVOS

**Data:** 31/01/2026  
**Status:** ⚠️ AGUARDANDO CREDENCIAIS AWS REAIS

---

## 🔴 PROBLEMA IDENTIFICADO

**Sintomas:**
- ❌ Fotos retornam 404 (não encontradas)
- ❌ PDFs falham ao carregar ("Failed to load PDF document")
- ❌ Vídeos não funcionam
- ❌ URL usa `/rails/active_storage/disk/` (armazenamento local)

**Causa Raiz:**
O sistema está configurado para usar AWS S3, mas com **credenciais falsas**:
```yaml
AWS_ACCESS_KEY_ID: "FAKE_LOCAL_KEY"
AWS_SECRET_ACCESS_KEY: "FAKE_LOCAL_SECRET"  
AWS_BUCKET: "local-storage"
```

---

## ✅ SOLUÇÃO IMPLEMENTADA

### 1. Arquivos Corrigidos ✅

**config/storage.yml** - Configurado para S3:
```yaml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  bucket: <%= ENV['AWS_BUCKET'] %>
  region: <%= ENV.fetch('AWS_REGION', 'sa-east-1') %>
  upload:
    cache_control: "public, max-age=31536000"
```

**config/environments/production.rb** - Ativado S3:
```ruby
config.active_storage.service = :amazon  # ✓ Mudado de :local para :amazon
```

---

## 🔧 PRÓXIMOS PASSOS (OBRIGATÓRIOS)

### Passo 1: Criar Bucket S3 na AWS

1. **Acesse o Console AWS**: https://console.aws.amazon.com/s3/
2. **Criar Bucket**:
   - Nome: `frotainstasolutions-storage` (ou outro nome único)
   - Região: **sa-east-1** (São Paulo)
   - Object Ownership: **ACLs disabled** (recomendado)
   - Block Public Access: **Desmarcar "Block all public access"**
   - Versioning: Desabilitado (opcional)
   - Criar bucket

3. **Configurar CORS** (Permissions → CORS):
```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
        "AllowedOrigins": [
            "https://app.frotainstasolutions.com.br",
            "http://app.frotainstasolutions.com.br"
        ],
        "ExposeHeaders": ["ETag"],
        "MaxAgeSeconds": 3000
    }
]
```

4. **Configurar Bucket Policy** (Permissions → Bucket Policy):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::frotainstasolutions-storage/*"
        }
    ]
}
```
> ⚠️ Substitua `frotainstasolutions-storage` pelo nome real do seu bucket!

---

### Passo 2: Criar Usuário IAM e Credenciais

1. **Acesse IAM**: https://console.aws.amazon.com/iam/
2. **Criar Usuário**:
   - Nome: `frotainstasolutions-app`
   - Access type: **Programmatic access** (Access key)
3. **Adicionar Permissões**:
   - Attach existing policies: **AmazonS3FullAccess**
   - OU criar policy customizada:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::frotainstasolutions-storage",
                "arn:aws:s3:::frotainstasolutions-storage/*"
            ]
        }
    ]
}
```
4. **Copiar Credenciais**:
   - Access key ID (exemplo: `AKIAIOSFODNN7EXAMPLE`)
   - Secret access key (exemplo: `wJalrXUtnFEMI/K7MDENG/bPxRfiCY...`)
   - ⚠️ **ATENÇÃO**: Guarde a secret key com segurança, ela só aparece uma vez!

---

### Passo 3: Configurar Credenciais no Servidor

**Conecte ao servidor:**
```bash
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200
```

**Edite o arquivo de configuração:**
```bash
sudo nano /var/www/frotainstasolutions/production/config/application.yml
```

**Substitua as linhas com credenciais falsas:**
```yaml
# ANTES (FAKE - NÃO FUNCIONA):
AWS_ACCESS_KEY_ID: "FAKE_LOCAL_KEY"
AWS_SECRET_ACCESS_KEY: "FAKE_LOCAL_SECRET"
AWS_REGION: "sa-east-1"
AWS_BUCKET: "local-storage"

# DEPOIS (CREDENCIAIS REAIS):
AWS_ACCESS_KEY_ID: "AKIAIOSFODNN7EXAMPLE"  # Sua Access Key real da AWS
AWS_SECRET_ACCESS_KEY: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # Sua Secret Key real
AWS_REGION: "sa-east-1"
AWS_BUCKET: "frotainstasolutions-storage"  # Nome do bucket que você criou
```

**Salvar e sair:**
- Pressione `Ctrl+X`
- Digite `Y` para confirmar
- Pressione `Enter`

---

### Passo 4: Reiniciar o Servidor

```bash
sudo systemctl restart frotainstasolutions
sleep 5
sudo systemctl status frotainstasolutions
```

**Verificar se está rodando:**
- Status deve mostrar: `Active: active (running)`
- Se houver erro, verificar logs: `sudo journalctl -u frotainstasolutions -n 50`

---

## 🧪 TESTE DE FUNCIONAMENTO

Após configurar as credenciais e reiniciar:

1. **Acesse o sistema**: https://app.frotainstasolutions.com.br
2. **Faça upload de um arquivo** (foto ou PDF)
3. **Verifique a URL gerada**: Deve ser algo como:
   ```
   https://frotainstasolutions-storage.s3.sa-east-1.amazonaws.com/...
   ```
   OU
   ```
   https://app.frotainstasolutions.com.br/rails/active_storage/blobs/...
   ```
4. **Abra o arquivo**: Deve carregar normalmente

---

## ⚠️ TROUBLESHOOTING

### Erro: "Access Denied" ou 403
**Causa**: Permissões incorretas no bucket ou IAM  
**Solução**: Verificar Bucket Policy e IAM permissions

### Erro: "Invalid Access Key"
**Causa**: Credenciais incorretas no application.yml  
**Solução**: Revisar AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY

### Erro: "Bucket does not exist"
**Causa**: Nome do bucket incorreto ou não existe  
**Solução**: Verificar AWS_BUCKET no application.yml e nome real do bucket na AWS

### Arquivos ainda retornam 404
**Causa**: Servidor não foi reiniciado após alteração  
**Solução**: `sudo systemctl restart frotainstasolutions`

### CORS Error no browser
**Causa**: CORS não configurado no bucket  
**Solução**: Adicionar configuração CORS no console S3

---

## 💰 CUSTOS AWS S3

**Estimativa para uso moderado:**
- Armazenamento: ~$0.023 por GB/mês (região sa-east-1)
- Transferência de dados: Primeiros 100GB/mês grátis, depois ~$0.15 por GB
- Requisições PUT: $0.005 por 1.000 requisições
- Requisições GET: $0.0004 por 1.000 requisições

**Exemplo prático:**
- 10GB armazenados = ~$0.23/mês
- 50.000 visualizações/mês = ~$0.02/mês
- **Total estimado: < $0.50/mês** para uso pequeno/médio

---

## 📞 SUPORTE

**Em caso de dúvidas:**
1. Verificar logs: `sudo journalctl -u frotainstasolutions -f`
2. Verificar configuração: `cat /var/www/frotainstasolutions/production/config/application.yml | grep AWS`
3. Testar conexão AWS: `cd /var/www/frotainstasolutions/production && RAILS_ENV=production bundle exec rails runner "puts ActiveStorage::Blob.service.bucket"`

---

## ✅ CHECKLIST DE CONFIGURAÇÃO

- [ ] Bucket S3 criado na AWS (região sa-east-1)
- [ ] CORS configurado no bucket
- [ ] Bucket Policy configurado (acesso público para leitura)
- [ ] Usuário IAM criado com permissões S3
- [ ] Access Key e Secret Key geradas
- [ ] Credenciais adicionadas em `config/application.yml`
- [ ] Servidor reiniciado
- [ ] Teste de upload realizado com sucesso
- [ ] Arquivos carregam corretamente (fotos, PDFs, vídeos)

---

**Status Atual:** ⏳ Aguardando que você configure as credenciais AWS reais  
**Próxima Ação:** Criar bucket S3 e usuário IAM na AWS Console
