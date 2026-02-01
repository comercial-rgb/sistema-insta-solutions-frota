# Guia para Iniciar o Sistema Insta Solutions Localmente

## ✅ Gems Instaladas com Sucesso!

As dependências do projeto foram instaladas com sucesso. 

## ⚠️ IMPORTANTE: Instalar o MySQL

Antes de iniciar o sistema, você precisa ter o MySQL instalado e rodando.

### Instalar MySQL no Windows:

1. **Baixe o MySQL**: https://dev.mysql.com/downloads/mysql/
2. **Instale** seguindo o assistente (recomendado: MySQL 8.0)
3. **Configure** a senha root durante a instalação
4. **Inicie o serviço MySQL**:
```powershell
net start MySQL80
```

### Ou use XAMPP (mais fácil):

1. **Baixe**: https://www.apachefriends.org/download.html
2. **Instale** e inicie o MySQL pelo painel do XAMPP

## Configuração do Banco de Dados

O sistema está tendo problemas para compilar gems nativas devido a problemas com o MSYS2/pacman no Ruby para Windows.

#### Solução A: Corrigir o MSYS2

1. Abra um terminal PowerShell como Administrador
2. Execute:
```powershell
ridk install
```
3. Escolha a opção 3 (MSYS2 and MINGW development toolchain)
4. Após a instalação, tente novamente:
```powershell
cd "C:\Users\Usuário\Desktop\sistema-insta-solutions"
bundle install
```

#### Solução B: Usar versões pré-compiladas das gems

Edite o Gemfile e force o uso de versões Windows pré-compiladas:

```ruby
# Substitua:
gem 'mysql2', '0.5.6'

# Por:
gem 'mysql2', '~> 0.5.6', platforms: [:mingw, :x64_mingw, :mswin]
```

### 2. Problema com Encoding do Path

O caminho contém caractere especial (á em "Usuário"). Sempre defina a variável LANG:

```powershell
$env:LANG = "en_US.UTF-8"
```

### 3. Configuração do Banco de Dados

1. Certifique-se de ter o MySQL instalado e rodando
2. Copie o arquivo de configuração:
```powershell
Copy-Item config\application.yml.example config\application.yml
```

3. Edite `config/application.yml` e configure:
```yaml
DATABASE_USERNAME_DEVELOPMENT: "root"
DATABASE_PASSWORD_DEVELOPMENT: "sua_senha_mysql"
```

## Passos para Iniciar o Sistema

### Opção 1: Usar o Script Automático

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\start.ps1
```

### Opção 2: Passo a Passo Manual

1. **Configurar encoding:**
```powershell
$env:LANG = "en_US.UTF-8"
```

2. **Instalar dependências** (pode levar alguns minutos):
```powershell
bundle install
```

3. **Configurar banco de dados:**
```powershell
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed  # Se houver seeds
```

4. **Iniciar o servidor:**
```powershell
bundle exec rails server -p 3000
```

5. **Acessar o sistema:**
Abra o navegador em: http://localhost:3000

## Comandos Úteis

- **Parar o servidor:** Ctrl+C no terminal
- **Verificar rotas:** `bundle exec rails routes`
- **Console Rails:** `bundle exec rails console`
- **Verificar gems:** `bundle check`
- **Limpar cache:** `bundle exec rails tmp:clear`

## Troubleshooting

### MySQL não está rodando
```powershell
# Inicie o serviço MySQL
net start MySQL80  # ou o nome do seu serviço MySQL
```

### Erro de conexão com banco de dados
Verifique:
- MySQL está rodando
- Credenciais em config/application.yml estão corretas
- Banco de dados existe (execute `rails db:create`)

### Porta 3000 já está em uso
Use outra porta:
```powershell
bundle exec rails server -p 3001
```

### Gems não instalam
Tente instalar gems individuais:
```powershell
gem install mysql2 --platform=ruby
gem install psych
```

## Notas Importantes

- Este é um sistema Rails 7.1.2 com Ruby 3.4.7
- Usa MySQL como banco de dados
- Requer gems nativas que podem precisar de ferramentas de compilação
- O sistema usa Figaro para gerenciar variáveis de ambiente
