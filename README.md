# Modern Galeria — MRV Vila de Setiba

Galeria de imagens/plantas/vídeos para injeção via script no 3DVista, hospedada no AWS S3.

**Projeto:** MRV — Vila de Setiba
**Tema:** verde imersivo (`#002E1D` / `#EAFFF7`)

---

## URLs de produção

| Arquivo | URL |
|---------|-----|
| Galeria | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/MRV/galeria-vila-de-setiba/index.html` |
| Vídeos  | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/MRV/galeria-vila-de-setiba/video-gallery.html` |
| Script  | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/MRV/galeria-vila-de-setiba/inject.js` |

**S3 path:** `s3://skylineip/Tour Virtual/MRV/galeria-vila-de-setiba/`

---

## Estrutura de arquivos

```
galeria/  (MRV / vila de setiba)
├── index.html              ← galeria de imagens + plantas (auto-suficiente)
├── video-gallery.html      ← galeria de vídeos (abas: Produto, Clipe Lançamento, Vertical, Vem aí)
├── diferenciais.html       ← ficha de diferenciais (scroll)
├── inject.js               ← loader leve para injeção no 3DVista
├── deploy.ps1              ← deploy para o S3 (Windows; normaliza case + sync)
├── generate_thumbs.ps1     ← gerador de thumbnails (Windows/GDI+, sem deps)
├── generate_thumbs.py      ← gerador alternativo (Python + Pillow)
└── assets/
    ├── imagens/              ← renders: áreas comuns (fachada, lazer, salão, happy hour) e
    │                            apartamento decorado (arquivos soltos, sem subpastas)
    ├── plantas/              ← implantação e plantas dos aptos 108, 901 e 904
    ├── videos/               ← .mp4 (gitignored; direto no S3)
    ├── BOOK-PRINT.pdf        ← book de referência (gitignored, não sobe ao S3)
    └── thumbs/               ← gerado automaticamente (espelha a árvore, .jpg)
```

> **Pastas = categorias.** Os nomes das pastas em `assets/` definem as categorias/subcategorias da galeria. Mantenha-os **minúsculos e sem espaços/acentos** (o S3 é case-sensitive).

---

## Categorias da galeria

### Modo `imagens`

| Categoria | Label | Pasta |
|-----------|-------|-------|
| `areas-comuns` | Áreas Comuns | `assets/imagens/` |
| `apartamento`  | Perspectivas Internas | `assets/imagens/` |

### Modo `plantas`

| Tipologia | Label | Pasta | Formato |
|-----------|-------|-------|---------|
| `pl-implantacao` | Implantação | `assets/plantas/` | card individual |
| `pl-apartamentos` | Apartamentos | `assets/plantas/` | cards individuais (aptos 108, 901, 904) |

---

## Cards de plantas com abas (`cobertura-plan`)

Plantas que são **níveis de um mesmo conjunto** podem ser agrupadas num único card com abas
que alternam (e sobrepõem) as variantes. Quando há **exatamente 2 pisos**, aparece também
o botão "Ver ambas" (comparação lado a lado); com mais pisos, só as abas. Nenhum item do
projeto atual usa esse formato — todas as plantas de Vila de Setiba são cards individuais —
mas o suporte permanece no motor da galeria para uso futuro:

```js
{ type:'cobertura-plan', category:'plantas', subCategory:'pl-apartamentos',
  title:'Pavimentos — Apartamentos', subtitle:'Apartamentos', floors:[
    { label:'Térreo',       src:'assets/plantas/terreo.jpg',       thumb:'assets/thumbs/plantas/terreo.jpg' },
    { label:'Tipo',         src:'assets/plantas/tipo.jpg',         thumb:'assets/thumbs/plantas/tipo.jpg' },
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
ignora `thumbs/`, `videos/` e o PDF.

> Alternativa multiplataforma: `python generate_thumbs.py` (requer Python + Pillow).

---

## Deploy AWS S3

> **Windows:** use o script pronto `./deploy.ps1` (faz o sync completo + `cache-control` no HTML/JS).
> Requer **AWS CLI** instalado e credenciais configuradas (`aws configure`) uma única vez.

### Sync completo

```bash
aws s3 sync . "s3://skylineip/Tour Virtual/MRV/galeria-vila-de-setiba/" \
  --exclude ".git/*" --exclude ".claude/*" --exclude "*.py" \
  --exclude "README.md" --exclude ".gitattributes" --exclude "*.md" \
  --exclude "deploy.ps1" --exclude "*.pdf" \
  --delete
```

### Atualizar só index.html e inject.js

```bash
aws s3 cp index.html "s3://skylineip/Tour Virtual/MRV/galeria-vila-de-setiba/index.html" \
  --cache-control "no-cache,no-store,must-revalidate"

aws s3 cp inject.js "s3://skylineip/Tour Virtual/MRV/galeria-vila-de-setiba/inject.js" \
  --cache-control "no-cache,no-store,must-revalidate"
```

> **`--cache-control "no-cache,no-store,must-revalidate"`** — essencial para garantir que o browser nunca sirva uma versão cacheada do script ou da galeria.

---

## Integração 3DVista

### Passo 1 — Loader (colocar no JavaScript global do projeto)

```js
(function(){
  var s = document.createElement('script');
  s.src = 'https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/MRV/galeria-vila-de-setiba/inject.js?v=' + Date.now();
  document.head.appendChild(s);
})();
```

> **`?v=` + `Date.now()`** — cache-busting: força o browser a baixar sempre a versão mais recente do script, evitando que o 3DVista sirva uma versão antiga em cache.

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

## Galeria de vídeos

Página `video-gallery.html`: uma aba por vídeo, player em tela cheia, mesmo tema verde.

| Aba | Arquivo | Observação |
|-----|---------|------------|
| Produto | `assets/videos/produto.mp4` | 4K, 1m26s — abre com autoplay (mudo) |
| Clipe Lançamento | `assets/videos/clipe-lancamento-horizontal.mp4` | 1920×1080 |
| Clipe Vertical | `assets/videos/clipe-lancamento-vertical.mp4` | 1080×1920 (9:16, centralizado) |
| Vem aí | `assets/videos/vem-ai.mp4` | 4K, 45s |

### Como aplicar

1. **Nome do arquivo:** minúsculo, sem espaços/acentos (o S3 é case-sensitive). Coloque em `assets/videos/`.
   Os vídeos são `.gitignore`d (pesados): sobem **direto para o S3**, não pelo git.
   A pasta `assets/video/` (singular) é só a origem bruta e é ignorada no deploy.
2. **Nova aba:** em `video-gallery.html`, duplique um `<button class="vg-tab" data-tab="x">` e o
   `<div id="tab-x" class="tab-panel">` com o `<video data-tab="x" src="assets/videos/arquivo.mp4">`
   (o `data-tab` do botão, o `id="tab-…"` e o `data-tab` do vídeo devem coincidir).
3. **Trocar vídeo:** altere o `src` do `<video>` correspondente (ou substitua o arquivo mantendo o nome).
4. **Subir:** `./deploy.ps1` (sync completo, inclui os vídeos). Para só a página: `aws s3 cp video-gallery.html "s3://skylineip/Tour Virtual/MRV/galeria-vila-de-setiba/video-gallery.html" --cache-control "no-cache,no-store,must-revalidate"`.
5. **Acionar no 3DVista** (hotspot/botão):

```js
AbrirGaleriaVideos(1);  // abre
AbrirGaleriaVideos(0);  // fecha
```

> Dica: vídeos 4K são pesados para mobile. Se necessário, gere versões 1080p
> (`ffmpeg -i in.mp4 -vf scale=-2:1080 -crf 24 -preset slow out.mp4`) e troque o `src`.

---

## Cores e tipografia

Tema **verde imersivo** do MRV — Vila de Setiba:

| Token CSS | Valor | Papel |
|-----------|-------|-------|
| `--bg` (fundo) | `#002E1D` | Verde-escuro principal (fundo) — cor primária |
| `--surface` | `#073C28` | Superfície de card |
| `--dark` (foreground) | `#EAFFF7` | Texto/ícones (verde-claro) — cor secundária |
| `--accent` | `#EAFFF7` | Destaque / estado ativo (usa a secundária sobre fundo escuro) |
| Fonte títulos | Cormorant Garamond | — |
| Fonte UI | Inter | — |

> Plantas técnicas mantêm **fundo claro** no card (`#EAFFF7`, para legibilidade do desenho), com texto verde-escuro (`#002E1D`) — a mesma dupla primária/secundária, com os papéis invertidos.
