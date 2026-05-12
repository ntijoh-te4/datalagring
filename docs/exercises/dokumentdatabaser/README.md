# Dokumentdatabaser, startbundle

Scaffold-kod för övningarna i kapitlet *Dokumentdatabaser*. Det är en minimal Pluggy-app (Elixir + Plug + Cowboy) som pratar med MongoDB.

Du behöver inte skriva någon Plug-, Cowboy- eller mallkod själv. Allt webb-relaterat finns redan. Din uppgift är att jobba med MongoDB-anropen i `lib/pluggy/models/` och, senare, lägga till en EventBus och prenumeranter.

## Förutsättningar

- Docker (för att köra MongoDB)
- Elixir 1.17+ och Erlang/OTP 26+

## Kör

Starta MongoDB:

```sh
docker compose up -d
```

Installera Elixir-bibliotek:

```sh
mix deps.get
```

Starta appen:

```sh
iex -S mix
```

Eller, om du föredrar att inte ha IEx-prompten:

```sh
mix run --no-halt
```

Öppna http://localhost:3000 i webbläsaren. Du ska se en (tom) lista över användare och ett formulär för att lägga till nya.

## Filer

- `lib/pluggy/application.ex` startar Mongo-klienten och webbservern.
- `lib/pluggy/router.ex` dirigerar inkommande HTTP-anrop.
- `lib/pluggy/controllers/` tar emot anropen och anropar modellerna.
- `lib/pluggy/models/` pratar med MongoDB.
- `priv/templates/` innehåller EEx-mallarna för HTML-vyerna.
- `docker-compose.yml` startar MongoDB.
