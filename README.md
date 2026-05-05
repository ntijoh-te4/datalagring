# Datalagring

Kurslitteratur för kursen *Datalagring* (Skolverket-kurserna **DATL100TX** och **DATL200TX**, Nivå 1 och Nivå 2) på NTI Gymnasiet. Boken författas i [AsciiDoc](https://asciidoc.org/) och publiceras automatiskt till GitHub Pages.

Publicerad version: <https://itggot.github.io/datalagring/>

## Innehåll

```
docs/
├── index.adoc                    Master-fil; inkluderar varje kapitel
├── index-docinfo.html            Injiceras i <head> — laddar mermaid.js
├── img/                          Bilder, organiserade per kapitel
│   └── 02_relationsdatabaser/
└── chapters/
    ├── 01_introduktion/
    ├── 02_relationsdatabaser/
    ├── 03_backup_och_aterstallning/
    ├── 04_no_sql/
    └── 05_utkast/                Utkast på sektioner som inte är inarbetade ännu
                                  (utkommenterad include i index.adoc — döljs från publicerad bok)
```

Varje kapitelkatalog har en `_chapter.adoc` som inkluderar de numrerade sektionerna i kapitlet.

## Bygga lokalt

Förutsättning: Ruby + `asciidoctor`-gemmen.

```sh
bundle install                                            # första gången
asciidoctor -D docs --backend=html5 -o index.html docs/index.adoc
open docs/index.html                                      # eller motsv. på din plattform
```

`docs/index.html` är ignorerad i `.gitignore` och ska aldrig committas.

### UML-diagram via mermaid

UML-klassdiagram i `4_datamodellering.adoc` renderas client-side via [mermaid.js](https://mermaid.js.org/) som laddas från CDN i `docs/index-docinfo.html`. Inga extra build-beroenden krävs lokalt — diagrammen ritas upp i webbläsaren när du öppnar `docs/index.html`.

## Bygga och publicera på GitHub

GitHub Actions tar hand om allt vid varje push till `master`:

- Workflow: `.github/workflows/asciidoctor.yml`
- Bygger med [`avattathil/asciidoctor-action`](https://github.com/avattathil/asciidoctor-action) (motsvarande lokala kommandot ovan)
- Deployar `docs/`-katalogen till branchen `gh-pages` med [`peaceiris/actions-gh-pages`](https://github.com/peaceiris/actions-gh-pages)
- GitHub Pages serverar från `gh-pages`

För att deploy ska fungera krävs en deploy key i repo-secrets under namnet `ACTIONS_DEPLOY_KEY`.

### Manuell deploy som fallback

När GitHub Actions är långsamt eller hänger sig kan du deploya direkt från en lokal maskin med:

```sh
bin/deploy
```

Scriptet bygger boken lokalt, sätter upp en git-worktree för `gh-pages`, synkar `docs/`-innehållet och pushar. Det förutsätter att du har push-rättigheter på remoten och en clean working tree på master.

Manuell deploy och Actions-deploy är inte exklusiva — om Actions-jobbet senare drar igång gör det sin egen force-push med samma innehåll (samma master-commit), så ingen konflikt uppstår.

## Aktivera utkast

Sektionen `05_utkast/` är dold från publicerad bok via en utkommenterad rad i `docs/index.adoc`:

```asciidoc
// include::chapters/05_utkast/_chapter.adoc[leveloffset=+1]
```

Ta bort `// ` för att inkludera utkasten i bygget — t.ex. för att läsa igenom dem inför att flytta något till bokens huvuddel.
