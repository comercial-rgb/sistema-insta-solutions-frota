# Configuração AWS S3 para Deploy em Produção

## Problema Resolvido

O erro `Aws::Errors::MissingRegionError` ocorria porque:
1. O ambiente de **test** estava configurado para usar S3 (`:amazon`)
2. O GitHub Actions executava `rails db:create` no ambiente de test
3. As credenciais AWS não estavam configuradas nos secrets do GitHub

## Mudanças Aplicadas

### 1. `config/environments/test.rb`
```ruby
# ANTES
config.active_storage.service = :amazon

# DEPOIS  
config.active_storage.service = :local
```

**Motivo**: Testes devem usar storage local (mais rápido, sem dependência de AWS).

### 2. `config/storage.yml`
```yaml
# ANTES
region: <%= ENV['AWS_BUCKET_REGION'] %>

# DEPOIS
region: <%= ENV.fetch('AWS_BUCKET_REGION', 'us-east-1') %>
```

**Motivo**: Fallback para `us-east-1` se a variável não estiver definida.

### 3. `config/initializers/active_storage.rb`
```ruby
# Adicionado tratamento de erro para não falhar se S3 não estiver configurado
if defined?(ActiveStorage::Blob) && ActiveStorage::Blob.service.present? rescue false
  # ... código existente
end
```

**Motivo**: Proteção contra erros durante inicialização se o serviço não estiver disponível.

## Configuração para Produção

Se você **realmente precisa de S3 em produção**, adicione estes secrets no GitHub:

1. Vá em: **Settings → Secrets and variables → Actions**
2. Adicione os seguintes secrets:

```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_BUCKET=your-bucket-name
AWS_BUCKET_REGION=us-east-1 (ou sua região)
AWS_BUCKET_PREFIX=uploads/ (opcional)
```

3. No workflow `.github/workflows/deploy-production.yml`, adicione as variáveis de ambiente:

```yaml
- name: Deploy to Production
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_BUCKET: ${{ secrets.AWS_BUCKET }}
    AWS_BUCKET_REGION: ${{ secrets.AWS_BUCKET_REGION }}
  run: |
    # seu comando de deploy
```

## Alternativa: Usar Storage Local em Produção

Se não precisar de S3, altere `config/environments/production.rb`:

```ruby
# ANTES
config.active_storage.service = :amazon

# DEPOIS
config.active_storage.service = :local
```

**Atenção**: Storage local não é recomendado para aplicações escaláveis com múltiplos servidores.

## Verificação

Teste localmente:

```bash
# Sem credenciais AWS (deve usar local)
RAILS_ENV=test bundle exec rails db:create

# Com credenciais AWS
AWS_BUCKET_REGION=us-east-1 RAILS_ENV=production bundle exec rails console
```

## Status Atual

✅ Ambiente de **test** configurado para usar storage local  
✅ Fallback de região adicionado ao storage.yml  
✅ Inicializador protegido contra erros  
⚠️ Ambiente de **production** ainda usa S3 (requer credenciais)

Se o deploy continuar falhando, considere mudar produção para `:local` temporariamente.
