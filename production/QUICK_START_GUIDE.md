# 🚀 Quick Start - Sistema Insta Solutions

## Início Rápido (Recomendado)

### Primeira vez
```powershell
# 1. Configurar banco de dados
Copy-Item config\application.yml.example config\application.yml
# Edite config\application.yml com suas credenciais do MySQL

# 2. Instalar dependências
bundle install

# 3. Criar banco e migrar
bundle exec rails db:create db:migrate

# 4. Iniciar servidor
.\quick-start.ps1
```

### Uso diário
```powershell
# Iniciar servidor (pula migrações se já executadas)
.\quick-start.ps1 -SkipMigrations

# Parar servidor
.\stop-server.ps1

# Ou pressione Ctrl+C no terminal do servidor
```

## 📋 Comandos Úteis

### Servidor
```powershell
# Iniciar com porta personalizada
.\quick-start.ps1 -Port 3001

# Iniciar com logs completos (debug)
.\quick-start.ps1 -Debug

# Verificar se está rodando
Invoke-WebRequest http://localhost:3000 -UseBasicParsing
```

### Banco de Dados
```powershell
# Criar banco
bundle exec rails db:create

# Executar migrações
bundle exec rails db:migrate

# Resetar banco (CUIDADO: apaga tudo)
bundle exec rails db:drop db:create db:migrate db:seed

# Verificar status de migrações
bundle exec rails db:migrate:status

# Console Rails (interagir com banco)
bundle exec rails console
```

### Testes e Qualidade
```powershell
# Executar testes
bundle exec rspec

# Verificar sintaxe de um arquivo
ruby -c caminho\do\arquivo.rb

# Listar rotas
bundle exec rails routes | Select-String "order_services"
```

### Manutenção
```powershell
# Limpar cache
Remove-Item tmp\cache\* -Recurse -Force

# Limpar logs antigos
Remove-Item log\*.log

# Limpar assets compilados
Remove-Item public\assets\* -Recurse -Force

# Reinstalar gems
Remove-Item -Recurse -Force vendor\bundle
bundle install
```

## 🔧 Solução de Problemas

### Servidor não inicia
```powershell
# 1. Verificar processos Ruby travados
Get-Process | Where-Object {$_.ProcessName -like "*ruby*"}

# 2. Parar todos
.\stop-server.ps1

# 3. Tentar novamente
.\quick-start.ps1
```

### Erro de migração
```powershell
# Verificar status
bundle exec rails db:migrate:status

# Rollback última migração
bundle exec rails db:rollback

# Refazer
bundle exec rails db:migrate
```

### Erro de gems
```powershell
# Limpar e reinstalar
Remove-Item Gemfile.lock
bundle install
```

### Porta em uso
```powershell
# Ver o que está usando a porta 3000
Get-NetTCPConnection -LocalPort 3000 | Select OwningProcess
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess

# Matar processo específico
Stop-Process -Id NUMERO_DO_PID -Force
```

## 📝 Configurações Importantes

### config/application.yml
```yaml
DATABASE_USERNAME_DEVELOPMENT: "root"
DATABASE_PASSWORD_DEVELOPMENT: "sua_senha"
```

### .env (se usar)
```
RAILS_ENV=development
DATABASE_URL=mysql2://root:senha@localhost/insta_solutions_development
```

## 🎯 Estrutura do Projeto

```
├── app/
│   ├── controllers/      # Lógica de requisições
│   ├── models/           # Modelos do banco
│   ├── views/            # Templates HTML/ERB
│   ├── assets/           # CSS, JS, imagens
│   └── services/         # Lógica de negócio
├── config/
│   ├── routes.rb         # Definição de rotas
│   ├── database.yml      # Config do banco
│   └── initializers/     # Configurações iniciais
├── db/
│   ├── migrate/          # Migrações do banco
│   └── seeds.rb          # Dados iniciais
└── spec/                 # Testes automatizados
```

## 🚨 Atalhos Criados

- **quick-start.ps1**: Inicia servidor com verificações inteligentes
- **stop-server.ps1**: Para todos os processos Ruby
- **OTIMIZACOES.md**: Dicas de performance

## 💡 Dicas de Desenvolvimento

1. **Use o quick-start.ps1** ao invés do start.ps1 original (mais rápido e inteligente)
2. **Mantenha o terminal aberto** para ver logs em tempo real
3. **Ctrl+C para parar** o servidor de forma limpa
4. **Use -SkipMigrations** no dia a dia para iniciar mais rápido
5. **Verifique logs** em `log/development.log` se houver erros

## 📞 Suporte

Em caso de dúvidas ou problemas:
1. Verifique os logs em `log/development.log`
2. Teste conexão do banco: `bundle exec rails db:migrate:status`
3. Limpe cache: `Remove-Item tmp\cache\* -Recurse -Force`
4. Reinicie: `.\stop-server.ps1` depois `.\quick-start.ps1`
