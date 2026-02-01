# Configuração S3 - Bucket Existente

## ✅ Bucket Já Criado

Você já tem o bucket: **frotainstasolutions-production**
- Região: **us-east-1** (US East N. Virginia)
- Criado em: 26 de janeiro de 2026

---

## 📋 PASSOS RÁPIDOS (5-10 minutos)

### 1️⃣ Verificar CORS do Bucket (2 min)

1. No console AWS S3, clique no bucket **frotainstasolutions-production**
2. Vá na aba **Permissions** (Permissões)
3. Role até **Cross-origin resource sharing (CORS)**
4. Clique em **Edit**
5. Cole este JSON:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
        "AllowedOrigins": [
            "https://app.frotainstasolutions.com.br",
            "http://localhost:3000"
        ],
        "ExposeHeaders": ["ETag"],
        "MaxAgeSeconds": 3000
    }
]
```

6. Clique em **Save changes**

---

### 2️⃣ Verificar Bucket Policy (2 min)

1. Na mesma página de **Permissions**
2. Role até **Bucket policy**
3. Clique em **Edit**
4. Se estiver vazio, cole este JSON:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::frotainstasolutions-production/*"
        }
    ]
}
```

5. Clique em **Save changes**

---

### 3️⃣ Verificar/Criar Usuário IAM (3 min)

**Opção A: Você já tem as credenciais?**
- Se já tem `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`, pule para o passo 4

**Opção B: Criar novo usuário IAM:**

1. No console AWS, vá em **IAM** → **Users**
2. Clique em **Create user**
3. Nome: `frotainstasolutions-app`
4. Selecione: **Access key - Programmatic access**
5. Clique **Next**
6. Em **Permissions**, selecione: **Attach policies directly**
7. Procure e selecione: **AmazonS3FullAccess**
8. Clique **Next** → **Create user**
9. **IMPORTANTE**: Copie e salve:
   - Access key ID
   - Secret access key
   (Não será possível ver novamente!)

---

### 4️⃣ Atualizar Credenciais no Servidor (2 min)

**No servidor de produção:**

```bash
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200

sudo nano /var/www/frotainstasolutions/production/config/application.yml
```

**Atualize estas linhas:**

```yaml
AWS_ACCESS_KEY_ID: "AKIAIOSFODNN7EXAMPLE"        # Sua chave real
AWS_SECRET_ACCESS_KEY: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # Seu secret real
AWS_REGION: "us-east-1"
AWS_BUCKET: "frotainstasolutions-production"
```

Salve: `Ctrl+O` → Enter → `Ctrl+X`

---

### 5️⃣ Deploy e Restart (2 min)

**No seu computador local:**

```powershell
# 1. Deploy do storage.yml atualizado
scp -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" config/storage.yml ubuntu@3.226.131.200:/tmp/

# 2. Copiar para produção
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200 "sudo cp /tmp/storage.yml /var/www/frotainstasolutions/production/config/"

# 3. Restart do servidor
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200 "sudo systemctl restart frotainstasolutions"

# 4. Verificar status
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200 "sudo systemctl status frotainstasolutions"
```

---

### 6️⃣ Testar Configuração (2 min)

**No servidor:**

```bash
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200

cd /var/www/frotainstasolutions/production
RAILS_ENV=production /home/ubuntu/.rbenv/shims/bundle exec rails runner /tmp/test_active_storage.rb
```

**Resultado esperado:**
```
✓ AWS_ACCESS_KEY_ID: AKIA... (configurado)
✓ AWS_SECRET_ACCESS_KEY: **** (configurado)
✓ AWS_REGION: us-east-1 (configurado)
✓ AWS_BUCKET: frotainstasolutions-production (configurado)
✓ Serviço S3 ativado corretamente!
✓ Gem aws-sdk-s3 instalada
✓ Conectando ao bucket... SUCESSO!
✓ Upload de teste... SUCESSO!
```

---

### 7️⃣ Migrar Arquivos Existentes (5-10 min)

**Apenas se o teste funcionar:**

```bash
cd /var/www/frotainstasolutions/production
RAILS_ENV=production /home/ubuntu/.rbenv/shims/bundle exec rails runner migrate_to_s3.rb
```

Isso vai migrar os **1100 arquivos (66MB)** do disco local para o S3.

---

## 🔍 Verificação Final

1. **No navegador**, acesse sua aplicação
2. Tente fazer upload de uma foto/PDF
3. Verifique se consegue visualizar o arquivo
4. Verifique se a URL mudou:
   - ❌ ANTES: `https://app.frotainstasolutions.com.br/rails/active_storage/disk/...`
   - ✅ DEPOIS: `https://frotainstasolutions-production.s3.us-east-1.amazonaws.com/...`

---

## ⚠️ Troubleshooting

### Erro: "Access Denied" ao fazer upload
**Solução:** Verifique se o usuário IAM tem a policy `AmazonS3FullAccess` anexada

### Erro: "Invalid bucket name"
**Solução:** Confirme que `AWS_BUCKET` está como `frotainstasolutions-production`

### Erro: "The bucket does not allow ACLs"
**Solução:** No console S3:
1. Vá em **frotainstasolutions-production** → **Permissions**
2. Em **Object Ownership**, clique **Edit**
3. Selecione **ACLs enabled**
4. Marque **Bucket owner preferred**
5. Salve

### Arquivos não carregam (CORS error)
**Solução:** Verifique se o CORS está configurado corretamente (passo 1)

---

## 💰 Custo Estimado

- **1100 arquivos (66MB)**: ~$0.002/mês de armazenamento
- **Requisições**: ~$0.01/mês (para tráfego médio)
- **Transferência**: Incluída nos primeiros 100GB/mês
- **TOTAL**: Menos de **$0.50/mês** 💚

---

## ✅ Checklist Rápido

- [ ] Bucket já existe: frotainstasolutions-production ✅
- [ ] CORS configurado
- [ ] Bucket Policy configurado
- [ ] Credenciais IAM obtidas
- [ ] application.yml atualizado no servidor
- [ ] storage.yml atualizado (região us-east-1)
- [ ] Servidor reiniciado
- [ ] Teste executado com sucesso
- [ ] Arquivos migrados para S3
- [ ] Upload/visualização funcionando

---

**Tempo total estimado: 10-15 minutos** ⚡
