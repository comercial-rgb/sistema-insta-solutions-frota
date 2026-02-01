# 🏗️ ARQUITETURA E HOSPEDAGEM
## Sistema Frota Insta Solutions

---

## 🎯 ENTENDENDO A ARQUITETURA

### ⚠️ IMPORTANTE: Sistema Monolítico (Tudo Integrado)

Este é um **sistema Rails tradicional (monolítico)**, onde:

```
┌─────────────────────────────────────────┐
│    SISTEMA RAILS (Back + Front)        │
│                                         │
│  ┌──────────────┐  ┌─────────────┐    │
│  │   BACKEND    │  │  FRONTEND   │    │
│  │  (Rails API) │  │  (Views)    │    │
│  │  Controllers │  │  HTML/CSS   │    │
│  │  Models      │  │  JavaScript │    │
│  └──────────────┘  └─────────────┘    │
│                                         │
│  Tudo roda no mesmo servidor Rails!    │
└─────────────────────────────────────────┘
```

**NÃO há separação de back e front!**  
- Não é React + API separados
- Não é Vue.js + API separados
- É tudo integrado no Rails (views ERB + controllers)

---

## 🖥️ O QUE VOCÊ PRECISA HOSPEDAR

### Opção 1: TUDO NO MESMO SERVIDOR (Recomendado para início)

```
┌────────────────────────────────────────┐
│  SERVIDOR ÚNICO                         │
│  (Ubuntu 22.04 LTS)                     │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  APLICAÇÃO RAILS                 │  │
│  │  - Backend (Controllers/Models)  │  │
│  │  - Frontend (Views ERB)          │  │
│  │  - Assets (CSS/JS)               │  │
│  │  Porta interna: 3000 (Puma)     │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  NGINX (Proxy Reverso)           │  │
│  │  Porta: 80 (HTTP) / 443 (HTTPS) │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  MYSQL (Banco de Dados)          │  │
│  │  Porta: 3306                     │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  STORAGE LOCAL                   │  │
│  │  Uploads, imagens, anexos        │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘

IP PÚBLICO: 200.100.50.25 (exemplo)
DNS: app.frotainstasolutions.com.br → 200.100.50.25
```

**✅ VANTAGENS:**
- Mais simples de configurar
- Custo mais baixo
- Menos complexidade
- Ideal para pequeno/médio porte

**❌ DESVANTAGENS:**
- Se o servidor cair, tudo cai
- Escalabilidade limitada

**💰 CUSTO ESTIMADO:**
- VPS/Servidor: R$ 80-200/mês
  - DigitalOcean: $40/mês (4GB RAM)
  - AWS EC2 t3.medium: ~$30/mês
  - Contabo: €8-20/mês
  - Hostinger VPS: R$ 80-150/mês

**📊 CONFIGURAÇÃO:**
- CPU: 2-4 cores
- RAM: 4-8 GB
- Disco: 50-100 GB SSD
- Tráfego: Ilimitado ou 10TB/mês

---

### Opção 2: SEPARADO (Banco em servidor próprio)

```
┌─────────────────────────────┐     ┌─────────────────────────┐
│  SERVIDOR 1 - APLICAÇÃO     │     │  SERVIDOR 2 - BANCO     │
│  (Ubuntu 22.04)             │     │  (Ubuntu 22.04)         │
│                             │     │                         │
│  ┌───────────────────────┐  │     │  ┌──────────────────┐  │
│  │  RAILS + NGINX        │  │────▶│  │  MYSQL 8.0       │  │
│  │  app.frotainstasol... │  │     │  │  Porta: 3306     │  │
│  └───────────────────────┘  │     │  └──────────────────┘  │
└─────────────────────────────┘     └─────────────────────────┘
   IP: 200.100.50.25                  IP: 200.100.50.26
                                      (privado/interno)
```

**✅ VANTAGENS:**
- Maior segurança (banco isolado)
- Melhor performance
- Backups independentes
- Escalabilidade

**❌ DESVANTAGENS:**
- Mais caro
- Mais complexo de configurar
- Precisa configurar rede interna

**💰 CUSTO ESTIMADO:**
- Servidor App: R$ 80-150/mês
- Servidor Banco: R$ 80-150/mês
- **TOTAL: R$ 160-300/mês**

---

### Opção 3: COM ARMAZENAMENTO NA NUVEM (AWS S3)

```
┌─────────────────────────────────────┐
│  SERVIDOR - APLICAÇÃO + BANCO       │
│  (Ubuntu 22.04)                     │
│                                     │
│  ┌────────────────────────────────┐│
│  │  RAILS + MYSQL + NGINX         ││
│  └────────────────────────────────┘│
│            │                        │
│            │ Upload de arquivos    │
│            ▼                        │
└─────────────────────────────────────┘
             │
             │ Internet
             ▼
    ┌─────────────────┐
    │   AWS S3        │
    │   (Storage)     │
    │                 │
    │  - Logos        │
    │  - Anexos       │
    │  - Imagens      │
    └─────────────────┘
```

**✅ VANTAGENS:**
- Arquivos não ocupam espaço no servidor
- Backup automático dos arquivos
- CDN global (mais rápido)
- Escalável

**❌ DESVANTAGENS:**
- Custo adicional
- Precisa configurar AWS

**💰 CUSTO ESTIMADO:**
- Servidor: R$ 80-150/mês
- AWS S3: R$ 10-50/mês (depende do uso)
- **TOTAL: R$ 90-200/mês**

---

## 🏢 ONDE HOSPEDAR? (Opções de Provedores)

### 🌎 Opção 1: VPS Nacional (Brasil)

**Hostinger VPS**
- Site: hostinger.com.br
- Preço: R$ 80-200/mês
- Localização: Brasil (São Paulo)
- Suporte: Português
- ✅ Recomendado para iniciantes

**UOLHost VPS**
- Site: uolhost.com.br
- Preço: R$ 100-300/mês
- Localização: Brasil
- Suporte: Português

**Locaweb VPS**
- Site: locaweb.com.br
- Preço: R$ 150-400/mês
- Localização: Brasil
- Suporte: Português

### 🌍 Opção 2: VPS Internacional (Melhor custo/benefício)

**DigitalOcean** ⭐ MAIS POPULAR
- Site: digitalocean.com
- Preço: $12-40/mês (R$ 60-200)
- Localização: São Paulo (datacenter BR)
- Documentação: Excelente
- ✅ Muito recomendado!

**Contabo**
- Site: contabo.com
- Preço: €8-20/mês (R$ 45-110)
- Melhor custo/benefício
- Localização: Europa/EUA

**Linode (Akamai)**
- Site: linode.com
- Preço: $12-40/mês
- Localização: São Paulo
- Performance excelente

**Vultr**
- Site: vultr.com
- Preço: $12-40/mês
- Localização: São Paulo
- Bom custo/benefício

### ☁️ Opção 3: Cloud (AWS, Azure, Google Cloud)

**AWS (Amazon Web Services)**
- Mais complexo
- Mais caro (mas escalável)
- Precisa conhecimento avançado
- R$ 200-500/mês (mínimo)

**Google Cloud**
- Similar ao AWS
- R$ 200-500/mês

**Azure (Microsoft)**
- Similar ao AWS
- R$ 200-500/mês

❌ **NÃO recomendado para iniciantes** (muito complexo e caro)

---

## 🎯 RECOMENDAÇÃO POR CENÁRIO

### Cenário 1: Pequeno Porte (até 50 usuários)

**RECOMENDAÇÃO:**
```
🖥️ 1 SERVIDOR VPS
   - Aplicação Rails + MySQL + Storage local
   - 4 GB RAM, 2 cores, 50 GB SSD

📍 PROVEDOR SUGERIDO:
   - DigitalOcean: Droplet $24/mês (4GB)
   - Contabo: VPS S €8.99/mês (4GB)
   - Hostinger: VPS 2 R$ 129/mês

💰 CUSTO: R$ 60-150/mês
```

### Cenário 2: Médio Porte (50-200 usuários)

**RECOMENDAÇÃO:**
```
🖥️ 1 SERVIDOR ROBUSTO
   - Aplicação Rails + MySQL
   - 8 GB RAM, 4 cores, 100 GB SSD

☁️ + AWS S3 (opcional)
   - Para armazenar arquivos/imagens

📍 PROVEDOR SUGERIDO:
   - DigitalOcean: $48/mês (8GB)
   - Linode: $48/mês (8GB)

💰 CUSTO: R$ 250-350/mês
```

### Cenário 3: Grande Porte (200+ usuários)

**RECOMENDAÇÃO:**
```
🖥️ SERVIDOR 1: Aplicação
   - Rails + Nginx
   - 8-16 GB RAM, 4-8 cores

🖥️ SERVIDOR 2: Banco de Dados
   - MySQL dedicado
   - 8 GB RAM, 4 cores

☁️ AWS S3
   - Todos os arquivos

💰 CUSTO: R$ 500-1000/mês
```

---

## 📋 RESUMO PRÁTICO - CONFIGURAÇÃO TÍPICA

### PARA A MAIORIA DOS CASOS (RECOMENDADO):

```
┌─────────────────────────────────────────────────┐
│  1 SERVIDOR VPS                                 │
│  ─────────────────                              │
│                                                 │
│  Provedor: DigitalOcean                        │
│  Plano: Droplet 4GB ($24/mês)                  │
│  Localização: São Paulo, BR                    │
│                                                 │
│  O QUE RODA NELE:                              │
│  ─────────────────                              │
│  ✅ Backend (Rails Controllers/Models)         │
│  ✅ Frontend (Views ERB)                        │
│  ✅ Banco de Dados (MySQL)                     │
│  ✅ Web Server (Nginx)                         │
│  ✅ Storage (arquivos locais)                  │
│                                                 │
│  URL: app.frotainstasolutions.com.br           │
│  SSL: Let's Encrypt (grátis)                   │
└─────────────────────────────────────────────────┘

💰 CUSTO TOTAL: ~R$ 120/mês
```

---

## 🚀 PASSO A PASSO SIMPLIFICADO

### 1️⃣ CONTRATAR SERVIDOR

**Exemplo: DigitalOcean**

```bash
# 1. Criar conta em digitalocean.com
# 2. Criar Droplet:
#    - Imagem: Ubuntu 22.04 LTS
#    - Plano: 4GB RAM / 2 cores ($24/mês)
#    - Região: São Paulo
#    - Autenticação: SSH Key (criar)
# 3. Aguardar criação (1-2 min)
# 4. Anotar IP público: ex: 200.100.50.25
```

### 2️⃣ CONFIGURAR DNS

```bash
# No painel do Registro.br (ou seu provedor):

Tipo: A
Nome: app
Valor: [IP_DO_SERVIDOR]
TTL: 3600

Resultado: app.frotainstasolutions.com.br → 200.100.50.25
```

### 3️⃣ FAZER DEPLOY

```bash
# Seguir o guia:
# DEPLOY_PRODUCAO_FROTAINSTASOLUTIONS.md

# Resumo:
ssh root@[IP_SERVIDOR]
# ... instalar dependências
# ... clonar código
# ... configurar
# ... iniciar
```

---

## ❓ PERGUNTAS FREQUENTES

### P: Preciso de 3 servidores separados?
**R:** NÃO! Um servidor único é suficiente para pequeno/médio porte.

### P: Back e front ficam separados?
**R:** NÃO! No Rails tudo é integrado, fica no mesmo servidor.

### P: Preciso contratar banco separado?
**R:** NÃO! MySQL roda no mesmo servidor da aplicação.

### P: Onde ficam as imagens/arquivos?
**R:** Por padrão no próprio servidor. Opcionalmente, pode usar AWS S3.

### P: Qual provedor você recomenda?
**R:** DigitalOcean (fácil de usar, datacenter no Brasil, boa documentação).

### P: Quanto vou gastar por mês?
**R:** R$ 120-150/mês para pequeno porte (servidor + domínio).

### P: Preciso conhecer AWS/Cloud?
**R:** NÃO! Um VPS simples é suficiente e muito mais fácil.

### P: E se o sistema crescer muito?
**R:** Aí sim vale separar banco e usar cloud. Mas comece simples!

---

## 📞 PRÓXIMOS PASSOS

1. ✅ **Escolher provedor** (recomendo DigitalOcean)
2. ✅ **Contratar VPS** (4GB RAM mínimo)
3. ✅ **Configurar DNS** (apontar app.frotainstasolutions.com.br)
4. ✅ **Seguir guia** [DEPLOY_PRODUCAO_FROTAINSTASOLUTIONS.md](DEPLOY_PRODUCAO_FROTAINSTASOLUTIONS.md)
5. ✅ **Testar sistema**

---

## 🎉 RESUMÃO FINAL

```
┌──────────────────────────────────────────────┐
│  O QUE VOCÊ PRECISA:                         │
│  ───────────────────                          │
│                                              │
│  ✅ 1 SERVIDOR VPS                           │
│     (DigitalOcean, Contabo, Hostinger...)    │
│     4GB RAM, 2 cores, 50GB SSD               │
│     Ubuntu 22.04 LTS                         │
│                                              │
│  ✅ 1 DOMÍNIO                                │
│     frotainstasolutions.com.br (você tem!)   │
│                                              │
│  ✅ SSL                                      │
│     Let's Encrypt (GRÁTIS)                   │
│                                              │
│  💰 CUSTO: ~R$ 120/mês                       │
│                                              │
│  📦 O QUE RODA NO SERVIDOR:                  │
│     - Rails (back + front integrados)        │
│     - MySQL (banco de dados)                 │
│     - Nginx (web server)                     │
│     - Storage (arquivos)                     │
│                                              │
│  🌐 RESULTADO:                               │
│     https://app.frotainstasolutions.com.br   │
│                                              │
└──────────────────────────────────────────────┘
```

---

**🎯 CONCLUSÃO: Você precisa de apenas 1 servidor VPS para rodar tudo!**

---

*Criado em: Janeiro 2026*
