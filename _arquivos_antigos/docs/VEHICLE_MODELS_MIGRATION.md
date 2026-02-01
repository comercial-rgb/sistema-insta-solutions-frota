# Guia de Migração: Vincular Veículos Existentes aos Modelos

## 📋 Situação

Você já possui muitos veículos cadastrados com o campo `model` (texto livre).
Agora temos a nova estrutura `vehicle_models` (tabela normalizada) e precisamos vincular os dados existentes.

## 🔧 Ferramentas Disponíveis

### 1️⃣ Ver estatísticas atuais
```powershell
bundle exec rails vehicle_models:stats
```
Mostra quantos veículos estão vinculados e quantos faltam.

---

### 2️⃣ Listar modelos únicos
```powershell
bundle exec rails vehicle_models:list_unique_models
```
Lista todos os modelos de veículos únicos que já existem no banco.
Use isso para ver quais modelos você precisa criar.

**Exemplo de saída:**
```
  127x | Carro               | FIAT MOBI 1.0
   89x | Carro               | TOYOTA COROLLA 2.0
   45x | Moto                | HONDA BIZ 125
```

---

### 3️⃣ Exportar para CSV
```powershell
bundle exec rails vehicle_models:export_unique_to_csv
```
Cria um arquivo CSV em `tmp/` com todos os modelos únicos.
Você pode editar esse arquivo e usar para criar modelos em massa.

---

### 4️⃣ Auto-vincular veículos existentes
```powershell
bundle exec rails vehicle_models:auto_link_all
```
**⚠️ Execute DEPOIS de criar os VehicleModels!**

Tenta vincular automaticamente todos os veículos aos modelos criados.
O sistema faz correspondência inteligente por:
- Nome completo (full_name)
- Aliases (nomes alternativos)
- Marca + Modelo parcial

---

## 📝 Fluxo Recomendado

### **PASSO 1:** Ver o que você tem
```powershell
bundle exec rails vehicle_models:stats
bundle exec rails vehicle_models:list_unique_models
```

### **PASSO 2:** Criar os VehicleModels

Você tem duas opções:

#### Opção A: Criar manualmente pela interface
- Acesse: http://localhost:3000/vehicle_models
- Clique em "Novo Modelo"
- Preencha os dados mais importantes (ex: FIAT MOBI 1.0, TOYOTA COROLLA)

#### Opção B: Importação em massa via CSV
1. Exportar CSV:
   ```powershell
   bundle exec rails vehicle_models:export_unique_to_csv
   ```

2. Editar o CSV gerado em `tmp/vehicle_models_import_*.csv`
   - Revisar marcas e modelos
   - Adicionar versões
   - Adicionar aliases (nomes alternativos)

3. Criar script de importação (ou criar pela interface web)

### **PASSO 3:** Auto-vincular veículos
```powershell
bundle exec rails vehicle_models:auto_link_all
```

### **PASSO 4:** Verificar resultado
```powershell
bundle exec rails vehicle_models:stats
```

---

## 🎯 Aliases (Nomes Alternativos)

Use aliases para capturar variações do mesmo modelo:

**Exemplo de VehicleModel:**
- **full_name:** FIAT MOBI 1.0 EASY
- **aliases:** ["MOBI", "MOBI 1.0", "FIAT MOBI", "MOBI EASY"]

Isso permite vincular veículos com textos como:
- "FIAT MOBI"
- "MOBI 1.0"
- "Fiat Mobi Easy"

---

## ⚡ Vincular Automaticamente Novos Veículos

Todos os veículos novos ou editados são automaticamente vinculados!
O sistema tem um callback `after_save` que tenta encontrar o VehicleModel correspondente.

---

## 📊 Exemplo Prático

```powershell
# 1. Ver situação atual
PS> bundle exec rails vehicle_models:stats
Veículos cadastrados: 450
  Com texto no modelo: 445
  Vinculados a VehicleModel: 0
  Não vinculados: 445

# 2. Listar modelos mais comuns
PS> bundle exec rails vehicle_models:list_unique_models
  127x | Carro | FIAT MOBI 1.0
   89x | Carro | TOYOTA COROLLA 2.0
  ...

# 3. Criar os 10 modelos mais usados pela interface web

# 4. Vincular automaticamente
PS> bundle exec rails vehicle_models:auto_link_all
Processando 445 veículos...
✓✓✓✓✓✓✓✓·····✓✓✓✓✓✓...

RESULTADO:
  Vinculados: 315
  Não vinculados: 130

# 5. Criar mais modelos para os restantes, repetir passo 4
```

---

## ❓ Dúvidas Comuns

**P: E se eu não criar todos os modelos?**
R: Tudo bem! Os veículos não vinculados continuam funcionando normalmente.
A vinculação é opcional e pode ser feita gradualmente.

**P: A validação de preço funciona sem vinculação?**
R: Não. Apenas veículos vinculados a um VehicleModel terão validação de preço Cilia.

**P: Posso executar o auto_link_all várias vezes?**
R: Sim! Ele processa apenas veículos ainda não vinculados.

---

## 🚀 Início Rápido (TL;DR)

```powershell
# Ver o que tem
bundle exec rails vehicle_models:list_unique_models

# Criar modelos principais pela web (http://localhost:3000/vehicle_models)

# Vincular automaticamente
bundle exec rails vehicle_models:auto_link_all

# Ver resultado
bundle exec rails vehicle_models:stats
```
