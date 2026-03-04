# 📘 Manual de Marca — Sistema Insta Solutions

> **Versão:** 1.0  
> **Data:** Março 2026  
> **Objetivo:** Documentar todas as características visuais, técnicas e de identidade do sistema Insta Solutions para replicação em outros sistemas.

---

## Índice

1. [Identidade Visual](#1-identidade-visual)
2. [Paleta de Cores](#2-paleta-de-cores)
3. [Tipografia](#3-tipografia)
4. [Logotipo e Favicon](#4-logotipo-e-favicon)
5. [Framework e Tecnologias de UI](#5-framework-e-tecnologias-de-ui)
6. [Componentes de Interface](#6-componentes-de-interface)
7. [Layout e Estrutura de Páginas](#7-layout-e-estrutura-de-páginas)
8. [Iconografia](#8-iconografia)
9. [Formulários e Inputs](#9-formulários-e-inputs)
10. [Badges e Status](#10-badges-e-status)
11. [Navegação e Menus](#11-navegação-e-menus)
12. [Páginas de Autenticação](#12-páginas-de-autenticação)
13. [Responsividade](#13-responsividade)
14. [Padrões de Espaçamento](#14-padrões-de-espaçamento)
15. [Impressão](#15-impressão)
16. [Configurabilidade (Multi-tenant)](#16-configurabilidade-multi-tenant)
17. [Checklist de Aplicação](#17-checklist-de-aplicação)

---

## 1. Identidade Visual

O sistema Insta Solutions segue uma identidade visual **moderna, limpa e corporativa**, baseada em:

- **Estética minimalista** com fundo claro e cards brancos com sombra suave
- **Cantos arredondados** (`border-radius: 8px`) em todos os componentes interativos
- **Sombras sutis** para criar hierarquia visual sem bordas explícitas
- **Cores vivas e contrastantes** entre primary (roxo escuro) e secondary (azul vibrante)
- **Espaçamento generoso** para facilitar leitura e interação

---

## 2. Paleta de Cores

### 2.1 Cores Principais (Theme Colors)

| Token        | Hex Code    | RGB                | Uso                                        |
|-------------|-------------|--------------------|--------------------------------------------|
| `$primary`  | `#251C59`   | `rgb(37, 28, 89)`  | Cor principal da marca. Menu ativo, botões primários, checkboxes, selects |
| `$secondary`| `#005BED`   | `rgb(0, 91, 237)`  | Links, breadcrumbs, ações secundárias      |
| `$success`  | `#46C026`   | `rgb(70, 192, 38)` | Confirmações, status aprovado              |
| `$info`     | `#2646C0`   | `rgb(38, 70, 192)` | Informações complementares                 |
| `$warning`  | `#F0B038`   | `rgb(240, 176, 56)`| Alertas, itens pendentes                   |
| `$danger`   | `#C02646`   | `rgb(192, 38, 70)` | Erros, exclusões, notificações urgentes    |
| `$light`    | `#E3E3E3`   | `rgb(227, 227, 227)`| Backgrounds secundários, bordas            |
| `$dark`     | `#000000`   | `rgb(0, 0, 0)`     | Textos enfáticos, títulos                  |

### 2.2 Cores de Interface

| Elemento                  | Cor          | Uso                                   |
|--------------------------|--------------|---------------------------------------|
| Background do body       | `#FAFAFA`    | Fundo geral de todas as páginas       |
| Texto do body            | `#333333`    | Texto principal                       |
| Card background          | `#FFFFFF`    | Fundo dos cards                       |
| Card text                | `rgba(19, 18, 18, 0.8)` | Texto de conteúdo dos cards |
| Card title               | `#000000`    | Títulos dentro de cards               |
| Card shadow              | `rgba(160, 160, 160, 0.25)` | Sombra dos cards        |
| Input background         | `rgba(128, 128, 128, 0.08)` | Fundo dos campos de input |
| Input text               | `#555555`    | Texto dos campos de input             |
| Input border (focus)     | `#747474`    | Borda do input quando focado          |
| Input placeholder        | `rgba(19, 18, 18, 0.6)` | Texto placeholder          |
| Input disabled text      | `rgba(19, 18, 18, 0.3)` | Texto de input desabilitado |
| Nav pills ativo          | `#516BCC`    | Background da aba ativa               |
| Nav background           | `#F4F4F4`    | Background da barra de navegação/tabs |
| Progress bar             | `#6F20D4`    | Barra de progresso (roxo)             |
| Progress background      | `#EAEAEA`    | Trilha da barra de progresso          |
| Range thumb              | `#516BCC`    | Thumb do slider/range                 |
| Notificação não lida     | `#EB0045`    | Círculo de notificação não lida       |
| Footer background        | `#f8f9fa`    | Background do rodapé fixo             |
| Brown (especial)         | `#795548`    | Usado em badges "emergencial"         |
| Accordion border         | `#D9D9D9`    | Borda dos accordions                  |
| Scrollbar thumb          | `#28a745`    | Cor da scrollbar customizada          |

### 2.3 Cores de Badges de Status (Ordem de Serviço)

| Badge                | Background   | Texto      | Borda      |
|---------------------|--------------|------------|------------|
| Diagnóstico         | `#fff3cd`    | `#212529`  | `#ffe69c`  |
| Cotações            | `#0d6efd`    | `#ffffff`  | `#0b5ed7`  |
| Requisição          | `#f8d7da`    | `#212529`  | `#f1aeb5`  |
| Emergencial         | `#d7ccc8`    | `#5d4037`  | `#bcaaa4`  |
| Cotações Diagnóstico| `#d1ecf1`    | `#0c5460`  | `#bee5eb`  |
| Complemento         | `#fff3cd`    | `#856404`  | `#ffc107`  |

### 2.4 Cores de Preço de Referência

| Badge               | Background   | Texto      | Borda      |
|---------------------|--------------|------------|------------|
| Preço excedido      | `#fff3cd`    | `#856404`  | `#ffc107`  |
| Preço OK            | `#d4edda`    | `#155724`  | `#c3e6cb`  |
| Sem referência      | `#f8f9fa`    | `#6c757d`  | `#dee2e6`  |

### 2.5 Setas de Comparação de Preço

| Contexto     | Cor        | Significado                |
|--------------|------------|---------------------------|
| Acima        | `#c8e6c9`  | Preço acima da referência  |
| Abaixo       | `#ffcdd2`  | Preço abaixo da referência |
| Similar      | `#e0e0e0`  | Preço próximo da referência|

---

## 3. Tipografia

### 3.1 Família Tipográfica

O sistema utiliza a **stack de fontes padrão do Bootstrap 5**, que inclui:

```
system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", "Noto Sans", 
"Liberation Sans", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", 
"Segoe UI Symbol", "Noto Color Emoji"
```

> **Fontes alternativas preparadas (comentadas no código):**
> - **Satoshi** (sans-serif) — `$font-family-sans-serif: 'Satoshi', sans-serif;`
> - **Spline Sans** (Google Fonts) — `$font-family-sans-serif: 'Spline Sans', sans-serif;`
> 
> Para ativar, descomentar no arquivo `style_guide/general.scss` ou `sulivam.scss`.

### 3.2 Escala Tipográfica

| Nível | Tamanho   | Uso                          |
|-------|-----------|------------------------------|
| H1    | `40px`    | Títulos principais de página |
| H2    | `32px`    | Subtítulos de seção          |
| H3    | `28px`    | Títulos de card/bloco        |
| H4    | `24px`    | Subtítulos secundários       |
| H5    | `20px`    | Labels de destaque           |
| H6    | `16px`    | Labels padrão                |
| fs-14 | `14px`    | Texto auxiliar, menus        |
| fs-12 | `12px`    | Captions, textos mínimos     |
| fs-8px| `8px`     | Micro textos                 |

### 3.3 Pesos Tipográficos

| Contexto       | Peso  |
|---------------|-------|
| Card title     | `700` (Bold)   |
| Card text      | `400` (Regular)|
| Botões         | `400` (Regular)|
| Tags           | `500` (Medium) |
| Badges         | `400` (Regular)|
| Labels de menu | `400` → `700` (hover/ativo) |

---

## 4. Logotipo e Favicon

### 4.1 Logo Principal

- **Arquivo:** `app/assets/images/logos/logo.png`
- **Formato:** PNG (com fundo transparente recomendado)
- **Nome da marca:** "Insta Solutions"
- **Símbolo corporativo:** `InstaSolutions-Símbolo-AzulCorp.png` (azul corporativo)

### 4.2 Aplicações do Logo

| Contexto                     | Largura  | Altura  |
|------------------------------|----------|---------|
| Tela de login                | `350px`  | auto    |
| Menu lateral aberto          | `70%` (max `140px`) | auto |
| Menu lateral fechado         | `80%`    | auto    |
| Menu responsivo (offcanvas)  | `120px`  | auto    |
| Cadastro de usuário          | `200px`  | auto    |
| Validação de e-mail          | `540px`  | `100px` |

### 4.3 Favicon

O sistema possui **sistema de 3 camadas de fallback** para favicons:

1. **Custom:** `/public/favicon/custom/favicon-{size}.png` (personalização por tenant)
2. **Asset pipeline:** `app/assets/images/favicon/favicon-{size}.png` (padrão do sistema)
3. **Fallback:** Pixel transparente em Base64

**Tamanhos requeridos:** `16x16`, `32x32`, `57x57`, `60x60`, `72x72`, `76x76`, `96x96`, `114x114`, `120x120`, `144x144`, `152x152`, `180x180`, `192x192`

### 4.4 Meta Tags OpenGraph

```html
<meta property="og:image" content="favicon-192x192.png">
<meta property="og:image:type" content="image/png">
<meta property="og:image:width" content="192">
<meta property="og:image:height" content="192">
<meta name="theme-color" content="#ffffff">
<meta name="msapplication-TileColor" content="#ffffff">
```

---

## 5. Framework e Tecnologias de UI

| Tecnologia          | Versão     | Uso                                    |
|---------------------|------------|----------------------------------------|
| Bootstrap           | `5.3.2`    | Framework CSS principal                |
| Bootstrap Icons     | `1.9.1`    | Biblioteca de ícones (CDN)             |
| jQuery              | `3.7.1`    | Manipulação DOM, plugins               |
| Select2             | `4.0.13`   | Selects com busca                      |
| Flatpickr           | `4.6.13`   | Date/time pickers                      |
| Bootstrap Datepicker| `1.10.0`   | Date pickers legados                   |
| Inputmask           | `5.0.8`    | Máscaras de input (CPF, CNPJ, etc)    |
| jQuery Mask Plugin  | `1.14.16`  | Máscaras adicionais                    |
| jQuery MaskMoney    | custom     | Máscara de valores monetários          |
| jQuery Validation   | `1.19.5`   | Validação de formulários               |
| Swiper              | `10.3.0`   | Carrosséis/sliders                     |
| ECharts             | `5.3.2`    | Gráficos e dashboards (CDN)            |
| DataTables          | `1.10.20`  | Tabelas com ordenação/busca (CDN)      |
| Moment.js           | `2.29.4`   | Manipulação de datas                   |
| SheetJS (xlsx)      | `0.18.5`   | Exportação de planilhas                |
| Popper.js           | `2.11.8`   | Posicionamento de tooltips/dropdowns   |
| SCSS                | via Rails  | Pré-processador CSS                    |

---

## 6. Componentes de Interface

### 6.1 Botões

```scss
// Tamanhos
Small:  font-size: 14px | padding: 5px 18px  | border-radius: 8px
Medium: font-size: 16px | padding: 8px 28px  | border-radius: 8px
Large:  font-size: 18px | padding: 10px 36px | border-radius: 8px

// Propriedades comuns
font-weight: 400
line-height: 32px
```

**Variantes utilizadas:**
- `btn-primary` — Ações principais (roxo `#251C59`)
- `btn-secondary` — Ações secundárias (azul `#005BED`)
- `btn-success` — Confirmações (verde `#46C026`)
- `btn-danger` — Exclusões/cancelamentos (vermelho `#C02646`)
- `btn-warning` — Atenção/pendências (amarelo `#F0B038`)
- `btn-light` — Botões neutros (cinza `#E3E3E3`)
- `btn-link` — Links como botão (sem background)

### 6.2 Tags

```scss
color: #FFFFFF
font-weight: 500
line-height: 32px
font-size: 16px
border-radius: 8px
padding: 7px 19px
cursor: default
```

### 6.3 Cards

```scss
border-width: none
border-color: none
box-shadow: rgba(160, 160, 160, 0.25)
border-radius: 15px
background: #FFFFFF
color: rgba(19, 18, 18, 0.8)

.card-title:
  color: #000000
  font-size: 18px
  font-weight: 700
  line-height: 24px

.card-text:
  font-size: 16px
  font-weight: 400
  line-height: 24px
```

### 6.4 Badges

```scss
font-size: 14px
font-weight: 400
color: #FFFFFF
padding: 6px 12px
border-radius: 20px   // pill shape
```

### 6.5 Accordions

```scss
border-color: #D9D9D9
border-radius: 12px
inner-border-radius: 12px
button-padding: 18px 24px
body-padding: 18px 24px
button-active-bg: #FFFFFF
button-active-color: #000000
```

### 6.6 Barra de Progresso

```scss
background: #6F20D4   // Roxo vibrante
track-bg: #EAEAEA
border-radius: 50px   // Pill shape
height: 32px
font-size: 16px
```

### 6.7 Nav Pills (Abas)

```scss
link-color: #131212
border-radius: 10px
padding: 0.9375rem 2.25rem
active-color: #FFFFFF
active-bg: #516BCC
nav-bg: #F4F4F4
```

### 6.8 Breadcrumbs (Tipo Ativo: "one")

```scss
link-color: $secondary (#005BED)
divider-color: $secondary
active-color: #000000
item-padding-x: 0.5rem
divider: "/"
font-size: 16px
```

---

## 7. Layout e Estrutura de Páginas

### 7.1 Estrutura Geral (Usuário Logado)

```
┌──────────────────────────────────────────────────────┐
│  [Menu Lateral]  │  [Barra Superior + Avatar]        │
│  15% largura     │  85% largura                      │
│  (ou 6% fechado) │  (ou 94% fechado)                 │
│                  │                                    │
│  Logo            │  ┌──────────────────────────────┐  │
│  Menu items      │  │  Breadcrumbs                 │  │
│  Submenus        │  │  Conteúdo da página          │  │
│                  │  │  Cards, tabelas, forms...     │  │
│                  │  └──────────────────────────────┘  │
│                  │                                    │
│                  │  [Footer fixo com links]           │
└──────────────────────────────────────────────────────┘
```

### 7.2 Dimensões do Menu Lateral

| Estado  | Largura Menu | Largura Conteúdo | Breakpoint     |
|---------|-------------|------------------|----------------|
| Aberto  | `15%`       | `85%`            | ≥ 992px        |
| Fechado | `6%`        | `94%`            | ≥ 992px        |
| Mobile  | Offcanvas   | `100%`           | < 992px        |

### 7.3 Barra Superior (Top Navigation)

- Background: `#FFFFFF` com sombra (`shadow-sm`)
- Container padrão do Bootstrap com padding `p-3`
- Alinhamento à direita: Sino de notificações + Dropdown de usuário
- Avatar do usuário: `50px × 50px`, `rounded-circle`
- Dropdown: `border-radius: 8px`, background branco

### 7.4 Footer Fixo

```scss
position: fixed
bottom: 0
background-color: #f8f9fa
padding: 10px 0
box-shadow: 0 -1px 5px rgba(0, 0, 0, 0.1)
height: 40px
```

Links do footer: `text-secondary`, `text-decoration-none`

### 7.5 Padding da Página

- Body: `margin-bottom: 60px` (espaço para footer)
- Conteúdo: `padding-bottom: 70px`

---

## 8. Iconografia

### 8.1 Biblioteca

**Bootstrap Icons** (versão 1.9.1 via CDN)

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.9.1/font/bootstrap-icons.css">
```

### 8.2 Padrão de Uso

Todos os ícones seguem a classe `bi bi-{nome}`:

```html
<i class="bi bi-speedometer2"></i>
```

### 8.3 Catálogo de Ícones Utilizados

**Menu Principal:**
| Ícone | Classe | Módulo |
|-------|--------|--------|
| Dashboard | `bi bi-speedometer2` | Dashboard |
| Clientes | `bi bi-building` | Clientes |
| Relatórios | `bi bi-bar-chart` | Relatórios |
| Faturas | `bi bi-receipt` | Financeiro |
| Relatórios Custom | `bi bi-file-earmark-bar-graph` | Relatórios Personalizados |
| Configurações | `bi bi-gear` | Tipos de Serviço |
| Contratos | `bi bi-file-earmark-text` | Contratos |
| Centros de Custo | `bi bi-wallet2` | Financeiro |
| Empenhos | `bi bi-clipboard-check` | Empenhos |
| Grupos de Serviço | `bi bi-collection` | Serviços |
| Peças e Serviços | `bi bi-tools` | Serviços |
| Veículos | `bi bi-truck` | Frota |
| Modelos | `bi bi-car-front` | Frota |
| Tipos de Veículos | `bi bi-ev-front` | Frota |
| Categorias | `bi bi-tags` | Categorias |
| Notificações | `bi bi-bell` | Sistema |
| Manuais | `bi bi-journal-bookmark` | Documentação |
| Suporte | `bi bi-headset` | Contato |
| Usuários | `bi bi-people` | Administração |
| Ordens de Serviço | `bi bi-card-list` | OS |
| Endereços | `bi bi-list` | Cadastros |
| Categorias | `bi bi-layers` | Categorias |

**Ações e Interface:**
| Ícone | Classe | Uso |
|-------|--------|-----|
| Editar | `bi bi-pencil-fill` | Botão de edição |
| Excluir | `bi bi-trash-fill` / `bi bi-trash` | Botão de exclusão |
| Adicionar | `bi bi-plus-circle` | Novo item |
| Info | `bi bi-info-circle` | Informações |
| Alerta | `bi bi-exclamation-triangle` | Avisos |
| Sucesso | `bi bi-check-circle-fill` | Confirmação |
| Erro | `bi bi-x-circle-fill` | Erro |
| Download | `bi bi-download` | Download |
| Busca | `bi bi-search` | Campos de busca |
| Segurança | `bi bi-shield-check` | Validação |
| Localização | `bi bi-geo-alt` | Endereço |
| Câmera | `bi bi-camera-fill` | Upload de foto |
| Emergencial | `bi bi-lightning-fill` | Urgência |
| Carrinho | `bi bi-cart-check-fill` | Pedidos |
| PDF | `bi bi-file-pdf` | Documento PDF |
| Excel | `bi bi-file-earmark-spreadsheet` | Planilha |
| Word | `bi bi-file-earmark-word` | Documento Word |
| Visualizar | `bi bi-eye` | Ver detalhes |
| Inbox | `bi bi-inbox` | Caixa de entrada |
| Favorito | `bi bi-bookmark-fill` | Marcador |
| Check | `bi bi-check-lg` / `bi bi-check-all` | Marcação |
| Configurar | `bi bi-gear-fill` | Config. avançada |
| Filtro | `bi bi-funnel` | Filtros |
| Lista | `bi bi-list-ul` | Listagem |
| Perfil | `bi bi-person-badge` | Dados do usuário |
| Sair | `bi bi-box-arrow-left` | Logout |
| Ajuda | `bi bi-question-circle-fill` | FAQ/Help |
| Idioma BR | `icon-brasil.png` | Bandeira Brasil |
| Idioma EN | `icon-estados-unidos.png` | Bandeira EUA |

---

## 9. Formulários e Inputs

### 9.1 Campo de Texto (Input)

```scss
font-size: 14px
font-weight: 400
line-height: 2
padding: 4px 10px      // (override via .form-control)
border-radius: 8px
background: rgba(128, 128, 128, 0.08)
color: #555555
border: 1px solid rgba(128, 128, 128, 0.08)
height: 38px

// Estados
hover:    border-color: #E7E7E7
focus:    border-color: #747474, box-shadow: none
disabled: bg: rgba(128, 128, 128, 0.08), color: rgba(19, 18, 18, 0.3)
```

### 9.2 Textarea

```scss
color: #555555
hover:    border-color: #E7E7E7, color: rgba(19, 18, 18, 0.6)
focus:    border-color: #747474, bg: rgba(128, 128, 128, 0.08), box-shadow: none
disabled: border-color: #FAFAFA, bg: #FAFAFA, color: rgba(19, 18, 18, 0.3)
```

### 9.3 Select (Select2)

```scss
border-radius: 8px
border: 1px solid rgba(128, 128, 128, 0.08)
background: rgba(128, 128, 128, 0.08)
height: 38px
font-size: 14px

// Dropdown
dropdown-bg: #FAFAFA
dropdown-border: 1px solid rgba(128, 128, 128, 0.08)
dropdown-border-radius: 8px (bottom)
dropdown-shadow: 0 .5rem 1rem rgba(0, 0, 0, .15)
highlighted: bg $primary (#251C59), color white
```

### 9.4 Checkbox

```scss
border-radius: 4px
width: 1.25em
checked-bg: $primary (#251C59)
```

### 9.5 Range Slider

```scss
track-height: 0.25rem
track-bg: rgba(188, 188, 188, 0.15)
track-border-radius: 20px
thumb-width: 0.5625rem
thumb-height: 0.5625rem
thumb-bg: #516BCC
thumb-border-radius: 50px
```

### 9.6 File Upload

```scss
file-selector-button:
  background: $primary (#251C59)
  color: white
```

### 9.7 Rich Text Editor

- **CKEditor** integrado
- Min-height do editor: `400px`

---

## 10. Badges e Status

### 10.1 Badge Padrão (Bootstrap Override)

```scss
font-size: 14px
font-weight: 400
color: #FFFFFF
padding: 6px 12px
border-radius: 20px    // formato pill
```

### 10.2 Badges Customizados de OS

Todos os badges de OS seguem este padrão:
```scss
font-size: 0.875rem
padding: 0.35em 0.65em
font-weight: 500
min-width: 90px
text-align: center
display: inline-block
border: 1px solid [cor-borda]
```

### 10.3 Badges de Preço (Minimalistas)

```scss
font-size: 0.75rem / 0.7rem
padding: 0.15rem 0.4rem
font-weight: 500 / 600
border-radius: padrão Bootstrap
```

---

## 11. Navegação e Menus

### 11.1 Menu Lateral Aberto

- Background: `#FFFFFF`
- Largura: `15%` da tela (fixo)
- Container: `position: fixed`, `height: 100vh`, `overflow-y: auto`
- Logo centralizado no topo
- Ícone de fechar: `bi bi-chevron-double-left` (alinhado à direita)

**Itens do menu:**
```scss
background: transparent
border: none
border-radius: 8px
font-size: 14px
line-height: 18px
padding: 12px
margin: 4px 0

// Hover e ativo
hover: bg: $primary (#251C59), color: #FFFFFF
ativo: class "bg-primary text-white"
```

**Sub-itens:**
```scss
padding: 12px 0 0 8px
hover: font-weight: 700
prefixo: ícone "bi bi-dot"
```

### 11.2 Menu Lateral Fechado

- Largura: `6%` da tela
- Apenas ícones visíveis (sem labels)
- Tooltips Bootstrap nos ícones
- Ícone de abrir: `bi bi-chevron-double-right`

### 11.3 Menu Responsivo (Offcanvas)

- Tipo: `offcanvas-end` (desliza da direita)
- Header: Logo (120px) + título "Menu" + botão de fechar
- Mensagem de boas-vindas com nome do usuário
- Lista de links tipo `list-group-flush`
- Seletor de idioma no rodapé

### 11.4 Dropdown do Usuário (Top Bar)

```scss
.dropdown-menu:
  border-radius: 8px
  background: white

.dropdown-item:hover:
  background: transparent

a:hover:
  color: $primary
```

### 11.5 Notificações (Sino)

```scss
ícone: bi bi-bell (fs-5, text-dark)
badge-quantidade:
  color: white
  font-size: 12px
  border-radius: 50%
  padding: 2px 6px
  background: $danger (#C02646)
```

---

## 12. Páginas de Autenticação

### 12.1 Login

**Estrutura:**
```
┌──────────────────────────────────────────┐
│                                          │
│           [Logo - 350px]                 │
│                                          │
│    ┌──── col-md-4 offset-md-4 ────┐     │
│    │  H3: "Entrar"                │     │
│    │  Label: E-mail               │     │
│    │  [Input e-mail]              │     │
│    │  Label: Senha                │     │
│    │  [Input senha]               │     │
│    │                              │     │
│    │  [Esqueceu a senha?] (link)  │     │
│    │            [Entrar] (btn)    │     │
│    │  [Seletor de idioma]         │     │
│    └──────────────────────────────┘     │
│                                          │
└──────────────────────────────────────────┘
```

- Sem barra de navegação (sem menu lateral)
- Logo centralizado com margem vertical (`my-5`)
- Formulário centralizado em `col-md-4 offset-md-4`
- Botão "Entrar": `btn-primary`, alinhado à direita

### 12.2 Cadastro

- Logo com `width: 200px`
- Formulário em `col-md-4 offset-md-4`
- Mesma estrutura centralizada

### 12.3 Login Social (OAuth)

```html
<!-- Google -->
btn-light w-100 my-1 + logos/google-logo.svg (20px)

<!-- Facebook -->
btn-light w-100 my-1 + logos/facebook-logo.svg (20px)
```

---

## 13. Responsividade

### 13.1 Breakpoints

O sistema usa os breakpoints padrão do Bootstrap 5:

| Breakpoint | Largura mínima |
|-----------|---------------|
| xs        | 0px           |
| sm        | 576px         |
| md        | 768px         |
| lg        | 992px         |
| xl        | 1200px        |
| xxl       | 1400px        |

### 13.2 Comportamento Customizado

| Breakpoint      | Comportamento                                         |
|-----------------|-------------------------------------------------------|
| `< 725px`       | `.mobile-none` → `display: none`                     |
| `≥ 725px`       | `.desktop-none` → `display: none`                    |
| `< 992px`       | Menu lateral escondido; Offcanvas habilitado          |
| `≥ 992px`       | Menu lateral fixo; Offcanvas desabilitado             |

### 13.3 Gráficos Responsivos (ECharts)

```scss
default:    height: 600px, width: 100%
≤ 768px:    height: 480px
≤ 576px:    height: 420px
```

---

## 14. Padrões de Espaçamento

### 14.1 Escala de Espaçamento

| Classe | Valor          | Pixels (base 16px) |
|--------|----------------|---------------------|
| `0`    | `0`            | 0px                 |
| `1`    | `0.25rem`      | 4px                 |
| `2`    | `0.5rem`       | 8px                 |
| `3`    | `1rem`         | 16px                |
| `4`    | `1.5rem`       | 24px                |
| `5`    | `3rem`         | 48px                |
| `6`    | `2rem`         | 32px                |
| `7`    | `2.5rem`       | 40px                |

> **Nota:** Os níveis 5, 6 e 7 não seguem ordem crescente. O nível 5 (`3rem`) é maior que 6 (`2rem`) e 7 (`2.5rem`).

### 14.2 Utilities Customizados

```scss
.h-100-vh   → height: 100vh
.radius-8   → border-radius: 8px
.fs-8px     → font-size: 8px
.fs-12px    → font-size: 12px
```

---

## 15. Impressão

### 15.1 Comportamento

- `.pagebreak` → `page-break-before: always`
- `.d-print-none` → esconde menu lateral, top bar e footer
- `.bg-danger-subtle` → preserva cor `#f8d7da` na impressão
- Cards de propostas: `page-break-inside: avoid`
- Containers com scroll: `max-height: none` na impressão

---

## 16. Configurabilidade (Multi-tenant)

O sistema foi projetado para ser **configurável por tenant** via model `SystemConfiguration`:

### 16.1 Elementos Configuráveis

| Elemento           | Campo                          | Fallback                    |
|-------------------|--------------------------------|-----------------------------|
| Título da página  | `system_configuration.page_title` | `t('session.project')` (i18n) |
| Descrição meta    | `system_configuration.page_description` | `t('session.project')` |
| Logo              | `logos/logo.png` (trocar asset)  | texto "Sistema" no alt      |
| Favicon           | `/public/favicon/custom/`       | Asset pipeline → base64     |
| Contrato provedor | `system_configuration.provider_contract` | `#`               |
| Textos do footer  | Sobre Produto, Política de Uso, Política de Privacidade | configurável |

### 16.2 Internacionalização (i18n)

- Suporte a **Português (BR)** e **Inglês (EN)**
- Seletor de idioma presente no login e menu responsivo
- Bandeiras: `icon-brasil.png` e `icon-estados-unidos.png`
- Chave principal: `session.project` define o nome do sistema

---

## 17. Checklist de Aplicação

Use este checklist ao aplicar a identidade do Insta Solutions em outro sistema:

### Cores e Tema
- [ ] Definir `$primary: #251C59` e `$secondary: #005BED` no arquivo de variáveis
- [ ] Configurar todas as 8 cores do theme-colors no SCSS
- [ ] Definir `$body-bg: #FAFAFA` e `$body-color: #333`
- [ ] Habilitar `$enable-rounded: true` e `$enable-shadows: true`

### Tipografia
- [ ] Configurar escala tipográfica (H1: 40px → H6: 16px)
- [ ] Adicionar tamanhos extras: `fs-14` (14px) e `fs-12` (12px)
- [ ] Usar font stack padrão do Bootstrap ou ativar Satoshi/Spline Sans

### Componentes
- [ ] Configurar botões com `border-radius: 8px` e 3 tamanhos (sm/md/lg)
- [ ] Configurar cards com `border-radius: 15px`, sem borda, com sombra
- [ ] Configurar badges pill com `border-radius: 20px`
- [ ] Configurar inputs com `border-radius: 8px` e fundo translúcido
- [ ] Configurar accordions com `border-radius: 12px`
- [ ] Configurar progress bar com `border-radius: 50px`

### Layout
- [ ] Implementar menu lateral fixo com toggle (15% ↔ 6%)
- [ ] Implementar offcanvas para mobile (< 992px)
- [ ] Implementar top bar com avatar e dropdown
- [ ] Implementar footer fixo com links institucionais
- [ ] Definir padding-bottom no body para compensar footer

### Iconografia
- [ ] Instalar Bootstrap Icons via CDN (v1.9.1+)
- [ ] Usar padrão `bi bi-{nome}` em todos os ícones
- [ ] Mapear ícones do menu conforme tabela na seção 8

### Assets
- [ ] Criar/substituir `logos/logo.png` com logo do novo sistema
- [ ] Gerar favicons em todos os 13 tamanhos requeridos
- [ ] Configurar fallback de favicon de 3 camadas
- [ ] Configurar meta tags OpenGraph

### Formulários
- [ ] Integrar Select2 com estilos customizados
- [ ] Configurar Flatpickr para date pickers
- [ ] Configurar Inputmask para CPF, CNPJ, telefone etc.
- [ ] Integrar CKEditor para campos rich text

### Responsividade
- [ ] Testar breakpoints de menu (992px)
- [ ] Testar breakpoints customizados (725px)
- [ ] Testar gráficos responsivos
- [ ] Validar impressão (elementos ocultos + cores preservadas)

### Multi-tenant
- [ ] Implementar `SystemConfiguration` para título, descrição, contrato
- [ ] Implementar sistema de favicon customizado por tenant
- [ ] Implementar i18n (pt-BR + en)

---

## Arquivos de Referência no Código-Fonte

Todos os estilos estão organizados na seguinte estrutura:

```
app/assets/stylesheets/
├── application.css.scss           # Entry point, imports globais
├── bootstrap-custom.css.scss      # Importa style_guide + Bootstrap
├── custom-brown.css.scss          # Classe utilitária marrom
├── datagrid-fix.scss              # Ajustes de tabelas Datagrid
├── flash.scss                     # Notificações flash
├── notifications.scss             # Indicador de notificação
├── order.scss                     # Helpers de forms de OS
├── order_service_proposals_compact.css # Layout compacto propostas
├── reference_price_badges.css     # Badges de preço referência
├── responsive.scss                # Classes mobile/desktop
├── select2-fix.css.scss           # Customização Select2
├── sulivam.scss                   # Tema alternativo (desabilitado)
└── style_guide/                   # ⭐ CORE DO DESIGN SYSTEM
    ├── _colors.scss               # Paleta de cores
    ├── _custom_variables.scss     # Variáveis customizadas
    ├── accordion.scss             # Estilos de accordion
    ├── badge.scss                 # Estilos de badge
    ├── breadcrumb.scss            # Estilos de breadcrumb
    ├── buttons.scss               # Estilos de botões
    ├── card.scss                  # Estilos de card
    ├── common.scss                # Utilitários comuns
    ├── font_sizes.scss            # Escala tipográfica
    ├── form_check.scss            # Checkbox/radio
    ├── general.scss               # Body, rounded, shadows
    ├── input.scss                 # Campos de input
    ├── menus.scss                 # Menu lateral + top nav
    ├── nav.scss                   # Nav pills/tabs
    ├── progress_bar.scss          # Barra de progresso
    ├── range.scss                 # Range slider
    ├── spacing.scss               # Escala de espaçamento
    ├── text_area.scss             # Textarea
    └── theme_colors.scss          # Mapa de cores do Bootstrap
```

---

> **Para aplicar em outro sistema:** copie a pasta `style_guide/` inteira, ajuste as cores em `_colors.scss`, substitua o logo em `logos/logo.png`, gere os favicons nos tamanhos listados, e importe tudo via `bootstrap-custom.css.scss` antes do `@import 'bootstrap/scss/bootstrap'`.
