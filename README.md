# Modern Galeria — Grupo Impper (Legacy)

Galeria de imagens/plantas/vídeos para injeção via script no 3DVista, hospedada no AWS S3.

**Projeto:** Grupo Impper — Legacy  
**Tema:** navy imersivo (`#183142` / `#FFFFFF` / `#E57D43`)

---

## URLs de produção

| Arquivo | URL |
|---------|-----|
| Galeria | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/grupo+impper/legacy/ferramentas/galeria/index.html` |
| Vídeos  | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/grupo+impper/legacy/ferramentas/galeria/video-gallery.html` |
| Script  | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/grupo+impper/legacy/ferramentas/galeria/inject.js` |

**S3 path:** `s3://skylineip/Tour Virtual/grupo impper/legacy/ferramentas/galeria/`

---

## Estrutura de arquivos

```
galeria/  (grupo impper / legacy)
├── index.html              ← galeria de imagens + plantas (auto-suficiente)
├── video-gallery.html      ← galeria de vídeos
├── diferenciais.html       ← ficha de diferenciais (scroll)
├── inject.js               ← loader leve para injeção no 3DVista
├── deploy.ps1              ← deploy para o S3 (Windows; normaliza case + sync)
├── generate_thumbs.ps1     ← gerador de thumbnails (Windows/GDI+, sem deps)
├── generate_thumbs.py      ← gerador alternativo (Python + Pillow)
└── assets/
    ├── residencial/
    │   ├── geral/            ← fachadas, lazer e áreas comuns
    │   ├── 2-dormitorios/    ← interiores apto 2 dorm.
    │   └── 3-dormitorios/    ← interiores apto 3 dorm.
    ├── corporativo/          ← fachada corporativa + lobby
    ├── fotomontagem/         ← fotomontagens (inserção urbana)
    ├── plantas/
    │   ├── implantacao/      ← níveis do empreendimento
    │   ├── corporativo/      ← pavimentos da torre corporativa
    │   ├── 2-dormitorios/    ← plantas humanizadas 2 dorm.
    │   └── 3-dormitorios/    ← plantas humanizadas 3 dorm.
    ├── videos/               ← .mp4 (gitignored; direto no S3)
    ├── BOOK-PRINT.pdf        ← book de referência (gitignored, não sobe ao S3)
    └── thumbs/               ← gerado automaticamente (espelha a árvore, .jpg)
```

> **Pastas = categorias.** Os nomes das pastas em `assets/` definem as categorias/subcategorias da galeria. Mantenha-os **minúsculos e sem espaços/acentos** (o S3 é case-sensitive).

---

## Categorias da galeria

### Modo `imagens`

| Categoria | Label | Sub-categorias | Pasta |
|-----------|-------|----------------|-------|
| `residencial` | Residencial | Geral · 2 Dormitórios · 3 Dormitórios | `assets/residencial/*` |
| `corporativo` | Corporativo | — | `assets/corporativo/` |
| `fotomontagem` | Fotomontagem | — | `assets/fotomontagem/` |

### Modo `plantas`

| Tipologia | Label | Pasta | Formato |
|-----------|-------|-------|---------|
| `pl-implantacao` | Implantação | `assets/plantas/implantacao/` | card de abas (3 níveis) |
| `pl-corporativo` | Corporativo | `assets/plantas/corporativo/` | card de abas (7 pavimentos) |
| `pl-2d` | 2 Dormitórios | `assets/plantas/2-dormitorios/` | cards individuais |
| `pl-3d` | 3 Dormitórios | `assets/plantas/3-dormitorios/` | cards individuais |

---

## Cards de plantas com abas (`cobertura-plan`)

Plantas que são **níveis de um mesmo conjunto** são agrupadas num único card com abas
que alternam (e sobrepõem) as variantes. Quando há **exatamente 2 pisos**, aparece também
o botão “Ver ambas” (comparação lado a lado); com mais pisos, só as abas.

```js
{ type:'cobertura-plan', category:'plantas', subCategory:'pl-corporativo',
  title:'Pavimentos — Corporativo', subtitle:'Torre Corporativa', floors:[
    { label:'Subsolo',      src:'assets/plantas/corporativo/subsolo.png',     thumb:'assets/thumbs/plantas/corporativo/subsolo.jpg' },
    { label:'Térreo',       src:'assets/plantas/corporativo/terreo.jpg',      thumb:'assets/thumbs/plantas/corporativo/terreo.jpg' },
    { label:'1º Pavimento', src:'assets/plantas/corporativo/pavimento-1.png', thumb:'assets/thumbs/plantas/corporativo/pavimento-1.jpg' },
    // ... até 5º Pavimento
]},
```

---

## Thumbnails

Todo `src` da grade usa um `thumb` leve (**900 px, JPEG q82**, achatado sobre branco).
Geração **sem dependências** no Windows via GDI+:

```powershell
# Gera apenas os que faltam / desatualizados
./generate_thumbs.ps1

# Regenera todos
./generate_thumbs.ps1 -Force
```

O script espelha `assets/` em `assets/thumbs/` (sempre `.jpg`, caminho minúsculo),
ignora `thumbs/`, `videos/` e o PDF. Última geração: **127 MB → 5,4 MB** (69 imagens).

> Alternativa multiplataforma: `python generate_thumbs.py` (requer Python + Pillow).

---

## Deploy AWS S3

> **Windows:** use o script pronto `./deploy.ps1` (faz o sync completo + `cache-control` no HTML/JS).
> Requer **AWS CLI** instalado e credenciais configuradas (`aws configure`) uma única vez.

### Sync completo

```bash
aws s3 sync . "s3://skylineip/Tour Virtual/grupo impper/legacy/ferramentas/galeria/" \
  --exclude ".git/*" --exclude ".claude/*" --exclude "*.py" \
  --exclude "README.md" --exclude ".gitattributes" --exclude "*.md" \
  --exclude "deploy.ps1" --exclude "*.pdf" \
  --delete
```

### Atualizar só index.html e inject.js

```bash
aws s3 cp index.html "s3://skylineip/Tour Virtual/grupo impper/legacy/ferramentas/galeria/index.html" \
  --cache-control "no-cache,no-store,must-revalidate"

aws s3 cp inject.js "s3://skylineip/Tour Virtual/grupo impper/legacy/ferramentas/galeria/inject.js" \
  --cache-control "no-cache,no-store,must-revalidate"
```

> **`--cache-control "no-cache,no-store,must-revalidate"`** — essencial para garantir que o browser nunca sirva uma versão cacheada do script ou da galeria.

---

## Integração 3DVista

### Passo 1 — Loader (colocar no JavaScript global do projeto)

```js
(function(){
  var s = document.createElement('script');
  s.src = 'https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/grupo+impper/legacy/ferramentas/galeria/inject.js?v=' + Date.now();
  document.head.appendChild(s);
})();
```

> **`?v=` + `Date.now()`** — cache-busting: força o browser a baixar sempre a versão mais recente do script, evitando que o 3DVista sirva uma versão antiga em cache.  
> Esse detalhe foi o que resolveu o problema de redirecionamento para a galeria de outro projeto.

### Passo 2 — Acionar nos hotspots/botões

```js
// Abre galeria de imagens
GaleriaImagens(1);

// Fecha galeria de imagens
GaleriaImagens(0);

// Abre galeria de plantas
GaleriaPlantas(1);

// Fecha galeria de plantas
GaleriaPlantas(0);
```

---

## Cores e tipografia

Tema **navy imersivo** do Grupo Impper:

| Token CSS | Valor | Papel |
|-----------|-------|-------|
| `--bg` (fundo) | `#183142` | Navy principal (fundo) |
| `--surface` | `#1f3d51` | Superfície de card |
| `--dark` (foreground) | `#FFFFFF` | Texto/ícones (branco) |
| `--accent` | `#E57D43` | Laranja — destaque / estado ativo |
| Fonte títulos | Cormorant Garamond | — |
| Fonte UI | Inter | — |

> Plantas técnicas mantêm **fundo branco** no card (para legibilidade do desenho), com texto navy.
> Cards de plantas: `#FFFFFF` de fundo, `#183142` de texto.
