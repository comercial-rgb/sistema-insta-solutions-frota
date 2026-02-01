# 📁 GUIA DE RECUPERAÇÃO - Storage Backup 22/01/2026

## 🎯 Objetivo

Recuperar arquivos do backup de **22/01/2026** e migrar para o S3, **preservando o banco de dados atual** (não perde nenhum dado criado após 22/01).

---

## 📋 PRÉ-REQUISITOS

✅ Backup da pasta `storage/` de 22/01/2026  
✅ Sistema atual funcionando (já testado e confirmado)  
✅ S3 configurado e funcionando (já validado)  

---

## 🚀 PASSO A PASSO

### 1️⃣ **Obter o Backup com a Equipe**

Solicite à equipe o backup da pasta `storage/` de **22/01/2026** ou antes de **27/01/2026**.

**Formato esperado:**
```
storage/
├── 01/
│   └── 23/
│       └── 0123abc...
├── 02/
│   └── 45/
│       └── 0245def...
└── ...
```

Ou compactado: `storage.tar.gz`, `storage.zip`, etc.

---

### 2️⃣ **Transferir Backup para o Servidor**

**Opção A: Se o backup estiver no seu computador**

```powershell
# Descompactar (se necessário)
Expand-Archive storage.zip -DestinationPath .\storage_backup

# Copiar para o servidor
scp -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" -r .\storage_backup ubuntu@3.226.131.200:/tmp/
```

**Opção B: Se o backup estiver em outro servidor/FTP**

```bash
# No servidor de produção
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200

# Baixar do FTP/outro servidor
wget http://backup-server.com/storage_22-01.tar.gz
tar -xzf storage_22-01.tar.gz -C /tmp/
mv /tmp/storage /tmp/storage_backup
```

---

### 3️⃣ **Verificar Estrutura do Backup**

```bash
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200

# Verificar que a pasta existe
ls -lah /tmp/storage_backup/

# Ver estrutura
find /tmp/storage_backup -type f | head -20

# Contar arquivos com conteúdo (>0 bytes)
find /tmp/storage_backup -type f -size +0 | wc -l
```

**Esperado:** Deve mostrar centenas de arquivos organizados em subpastas de 2 caracteres.

---

### 4️⃣ **Transferir Script de Recuperação**

```powershell
# Do seu computador local
scp -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" recuperar_storage_backup.rb ubuntu@3.226.131.200:/tmp/
```

---

### 5️⃣ **Executar Recuperação**

```bash
# Conectar no servidor
ssh -i "C:\Users\Usuário\.ssh\frotainstasolutions-keypair.pem" ubuntu@3.226.131.200

# Ir para o diretório da aplicação
cd /var/www/frotainstasolutions/production

# Executar script
RAILS_ENV=production /home/ubuntu/.rbenv/shims/bundle exec rails runner /tmp/recuperar_storage_backup.rb
```

**O script vai:**
- ✅ Verificar cada arquivo no backup
- ✅ Comparar com blobs no banco ATUAL
- ✅ Migrar para S3 apenas arquivos que faltam
- ✅ Ignorar arquivos que já estão no S3
- ✅ Preservar 100% do banco de dados atual

**Tempo estimado:** 
- ~5-10 minutos para 800+ arquivos
- Depende da velocidade de upload para S3

---

### 6️⃣ **Verificar Resultado**

Ao final, o script mostra:

```
📊 RELATÓRIO FINAL
================================================================================

Total de blobs no banco:        1057
Arquivos encontrados no backup: 834
Já existiam no S3:              193
Arquivos vazios (ignorados):    0

✅ Migrados com sucesso:        834
❌ Erros:                       0

📦 Total migrado:               ~55 MB

🎉 RECUPERAÇÃO CONCLUÍDA COM SUCESSO!
```

---

### 7️⃣ **Teste no Sistema**

Acesse o sistema e teste:

1. Abra uma OS antiga (criada antes de 27/01)
2. Clique em fotos/PDFs anexados
3. Verifique se abrem corretamente
4. Teste download de arquivos

---

### 8️⃣ **Limpeza (Opcional)**

Depois de confirmar que tudo funciona:

```bash
# Limpar backup temporário do servidor
rm -rf /tmp/storage_backup

# Limpar objetos vazios do S3 (economiza custos)
cd /var/www/frotainstasolutions/production
RAILS_ENV=production /home/ubuntu/.rbenv/shims/bundle exec rails runner /tmp/cleanup_s3_empty.rb
```

---

## 🔍 SOLUÇÃO DE PROBLEMAS

### ❌ Erro: "Pasta de backup não encontrada"

**Causa:** Caminho incorreto ou backup não copiado

**Solução:**
```bash
# Verificar se existe
ls -la /tmp/storage_backup

# Se não existir, copie novamente
# Certifique-se que o nome é exatamente "storage_backup"
```

---

### ❌ Erro: "Access Denied" no S3

**Causa:** Credenciais AWS incorretas

**Solução:**
```bash
# Verificar credenciais
cat /var/www/frotainstasolutions/production/config/application.yml | grep AWS

# Testar upload manual
cd /var/www/frotainstasolutions/production
RAILS_ENV=production /home/ubuntu/.rbenv/shims/bundle exec rails runner /tmp/test_s3_upload.rb
```

---

### ⚠️ Poucos arquivos migrados

**Possíveis causas:**
1. Backup incompleto/corrompido
2. Arquivos já estavam no S3 (OK!)
3. Estrutura de pastas diferente

**Verificação:**
```bash
# Contar arquivos válidos no backup
find /tmp/storage_backup -type f -size +0 | wc -l

# Deve mostrar ~800+ arquivos
```

---

## 📊 RESULTADO ESPERADO

**Antes da recuperação:**
- 193 arquivos no S3 ✅
- 834 arquivos perdidos ❌

**Após a recuperação:**
- **1027 arquivos no S3** ✅✅✅
- 0 arquivos perdidos 🎉
- Banco de dados atual preservado ✅
- Dados criados após 22/01 intactos ✅

---

## ⚠️ IMPORTANTE

**O que este processo FAZ:**
- ✅ Recupera arquivos do backup
- ✅ Migra para S3
- ✅ Preserva banco atual
- ✅ Não perde nenhum dado novo

**O que este processo NÃO FAZ:**
- ❌ NÃO restaura banco de dados antigo
- ❌ NÃO deleta dados criados após 22/01
- ❌ NÃO substitui arquivos que já estão OK no S3

---

## 📞 SUPORTE

Se tiver problemas durante a recuperação:

1. **Anote a mensagem de erro completa**
2. **Tire screenshot do relatório final**
3. **Verifique logs:** `/var/www/frotainstasolutions/production/log/production.log`

---

**Data do guia:** 01/02/2026  
**Versão:** 1.0  
**Status do sistema:** ✅ Funcionando (novos uploads OK)
