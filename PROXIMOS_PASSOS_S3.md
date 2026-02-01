# 🚀 CORREÇÃO DE ANEXOS - PRÓXIMOS PASSOS

## ✅ O QUE JÁ FOI FEITO

1. ✅ **Código corrigido e deployado:**
   - `config/storage.yml` - Configurado para AWS S3
   - `config/environments/production.rb` - Active Storage usando `:amazon`
   - Gem `aws-sdk-s3` já instalada (v1.194.0)

2. ✅ **Arquivos no servidor:**
   - `/var/www/frotainstasolutions/production/configure_aws_s3.sh` - Script auxiliar
   - Servidor **NÃO** foi reiniciado ainda (aguardando credenciais)

## ⚠️ O QUE VOCÊ PRECISA FAZER AGORA

### OPÇÃO 1: Configuração Rápida (Recomendado)

**1. Crie um bucket S3:**
   - Nome: `frotainstasolutions-storage`
   - Região: `sa-east-1`
   - Desmarque "Block all public access"

**2. Configure CORS no bucket (Permissions → CORS):**
```json
[{"AllowedHeaders":["*"],"AllowedMethods":["GET","PUT","POST","DELETE"],"AllowedOrigins":["https://app.frotainstasolutions.com.br"],"MaxAgeSeconds":3000}]
```

**3. Adicione Bucket Policy (Permissions → Bucket Policy):**
```json
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::frotainstasolutions-storage/*"}]}
```

**4. Crie usuário IAM:**
   - Nome: `frotainstasolutions-app`
   - Permissões: **AmazonS3FullAccess**
   - Tipo: **Programmatic access**
   - **Copie Access Key ID e Secret Access Key**

**5. Configure no servidor:**
```bash
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200
sudo nano /var/www/frotainstasolutions/production/config/application.yml
```

**Substitua:**
```yaml
AWS_ACCESS_KEY_ID: "FAKE_LOCAL_KEY"          # ← Trocar
AWS_SECRET_ACCESS_KEY: "FAKE_LOCAL_SECRET"  # ← Trocar
AWS_BUCKET: "local-storage"                  # ← Trocar

# Por (suas credenciais reais):
AWS_ACCESS_KEY_ID: "AKIA..."                 # ← Sua chave
AWS_SECRET_ACCESS_KEY: "..."                 # ← Sua secret
AWS_BUCKET: "frotainstasolutions-storage"    # ← Nome do bucket
```

**6. Reinicie o servidor:**
```bash
sudo systemctl restart frotainstasolutions
```

**7. Teste:**
```bash
cd /var/www/frotainstasolutions/production
RAILS_ENV=production /home/ubuntu/.rbenv/shims/bundle exec rails runner /tmp/test_active_storage.rb | grep -v warning
```

### OPÇÃO 2: Usar Script Auxiliar

```bash
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200
cd /var/www/frotainstasolutions/production
./configure_aws_s3.sh
```

---

## 📊 STATUS ATUAL DO SISTEMA

- **Active Storage:** ✅ Configurado para S3 (serviço: amazon)
- **Gem aws-sdk-s3:** ✅ Instalada (v1.194.0)
- **Credenciais AWS:** ❌ Usando credenciais falsas
- **Anexos no sistema:** 293 arquivos (precisam de credenciais reais para funcionar)

**O sistema está 99% pronto!** Só falta você adicionar as credenciais AWS reais.

---

## 🎯 RESULTADO ESPERADO

**ANTES (não funciona):**
```
❌ https://app.frotainstasolutions.com.br/rails/active_storage/disk/...
   → Retorna 404
```

**DEPOIS (vai funcionar):**
```
✅ https://frotainstasolutions-storage.s3.sa-east-1.amazonaws.com/...
   → Arquivo carrega normalmente
```

---

## 📞 PRECISA DE AJUDA?

1. **Console AWS:** https://console.aws.amazon.com/
2. **Guia completo:** Veja o arquivo `AWS_S3_SETUP_GUIDE.md`
3. **Verificar status:** Execute `test_active_storage.rb` no servidor

---

## ⏱️ TEMPO ESTIMADO

- Criar bucket S3: **2 minutos**
- Criar usuário IAM: **3 minutos**
- Configurar credenciais: **2 minutos**
- Reiniciar servidor: **1 minuto**

**Total: ~10 minutos** para resolver completamente! 🚀

---

## 💡 DICA IMPORTANTE

Os 293 anexos existentes já estão no Active Storage. Quando você configurar o S3:
- ✅ Novos uploads vão direto para o S3
- ⚠️ Anexos antigos podem precisar de migração (se estiverem em storage local)
- Verifique se os anexos antigos carregam após a configuração
