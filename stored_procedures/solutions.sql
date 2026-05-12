-- ============================================================================
-- solutions.sql: exempelsvar för Kapitel 2.7 Stored Procedures och Triggers
--
-- Körs mot en fräsch databas:
--   cd docs/exercises/stored_procedures && docker compose up -d
--   docker compose exec -T db psql -U student -d bokforing < ../../../stored_procedures/solutions.sql
--
-- Filen ligger utanför docs/ med flit; den publiceras inte till gh-pages
-- och delas inte med studenterna.
-- ============================================================================


-- ============================================================================
-- Övning: Function: saldo
-- ============================================================================
-- Returnerar saldot för ett konto, beräknat från konteringar-tabellen.
-- Tecknet beror på kontots typ:
--   tillgång/kostnad → SUM(debet) − SUM(kredit)
--   skuld/eget_kapital/intäkt → SUM(kredit) − SUM(debet)

CREATE FUNCTION saldo(konto_nummer TEXT) RETURNS NUMERIC AS $$
DECLARE
  k_typ TEXT;
  total NUMERIC;
BEGIN
  SELECT typ INTO k_typ FROM konton WHERE nummer = konto_nummer;
  IF k_typ IN ('tillgång', 'kostnad') THEN
    SELECT COALESCE(SUM(debet) - SUM(kredit), 0) INTO total
      FROM konteringar WHERE konto = konto_nummer;
  ELSE
    SELECT COALESCE(SUM(kredit) - SUM(debet), 0) INTO total
      FROM konteringar WHERE konto = konto_nummer;
  END IF;
  RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Alternativ kortare lösning med CASE i ren SQL:
--
--   CREATE FUNCTION saldo(konto_nummer TEXT) RETURNS NUMERIC AS $$
--     SELECT CASE
--       WHEN (SELECT typ FROM konton WHERE nummer = konto_nummer)
--            IN ('tillgång', 'kostnad')
--         THEN COALESCE(SUM(debet) - SUM(kredit), 0)
--         ELSE COALESCE(SUM(kredit) - SUM(debet), 0)
--     END
--     FROM konteringar WHERE konto = konto_nummer;
--   $$ LANGUAGE SQL;


-- ============================================================================
-- Övning: Procedure: bokför
-- ============================================================================
-- Tvårads-verifikat. Balans garanterad strukturellt (samma belopp på båda
-- sidor). Allt eller inget: om någon INSERT failar (t.ex. FK-violation på
-- konto_debet/kredit) rullas hela proceduren tillbaka.

CREATE PROCEDURE bokför(
  v_datum DATE,
  v_beskrivning TEXT,
  konto_debet TEXT,
  konto_kredit TEXT,
  belopp NUMERIC
) AS $$
DECLARE
  v_id INTEGER;
BEGIN
  INSERT INTO verifikat (datum, beskrivning)
    VALUES (v_datum, v_beskrivning) RETURNING id INTO v_id;
  INSERT INTO konteringar (verifikat_id, konto, debet, kredit)
    VALUES (v_id, konto_debet, belopp, 0);
  INSERT INTO konteringar (verifikat_id, konto, debet, kredit)
    VALUES (v_id, konto_kredit, 0, belopp);
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- Utforska vidare: Procedure: bokför_försäljning
-- ============================================================================
-- Treradigt försäljningsverifikat med 25% moms:
--   Bank D = brutto
--   Utgående moms K = moms
--   Försäljning vara 25% K = netto

CREATE PROCEDURE bokför_försäljning(
  v_datum DATE,
  brutto NUMERIC
) AS $$
DECLARE
  v_id INTEGER;
  moms  NUMERIC := brutto * 0.25 / 1.25;
  netto NUMERIC := brutto - moms;
BEGIN
  INSERT INTO verifikat (datum, beskrivning)
    VALUES (v_datum, 'Försäljning') RETURNING id INTO v_id;
  INSERT INTO konteringar (verifikat_id, konto, debet, kredit)
    VALUES (v_id, '1930', brutto, 0);
  INSERT INTO konteringar (verifikat_id, konto, debet, kredit)
    VALUES (v_id, '2610', 0, moms);
  INSERT INTO konteringar (verifikat_id, konto, debet, kredit)
    VALUES (v_id, '3001', 0, netto);
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- Övning: Trigger: hålla saldot uppdaterat
-- ============================================================================
-- Uppdaterar konton.saldo automatiskt när en ny kontering läggs till.
-- Samma sign-logik som saldo()-funktionen.
--
-- OBS: Triggern måste skapas FÖRE några bokföringar görs, annars är cachen
-- inte i synk med konteringarna. För en sent skapad trigger kan man
-- backfilla via:  UPDATE konton k SET saldo = saldo(k.nummer);

CREATE FUNCTION uppdatera_saldo() RETURNS TRIGGER AS $$
DECLARE
  k_typ TEXT;
  delta NUMERIC;
BEGIN
  SELECT typ INTO k_typ FROM konton WHERE nummer = NEW.konto;
  IF k_typ IN ('tillgång', 'kostnad') THEN
    delta := NEW.debet - NEW.kredit;
  ELSE
    delta := NEW.kredit - NEW.debet;
  END IF;
  UPDATE konton SET saldo = saldo + delta WHERE nummer = NEW.konto;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER konteringar_uppdatera_saldo
  AFTER INSERT ON konteringar
  FOR EACH ROW
  EXECUTE FUNCTION uppdatera_saldo();


-- ============================================================================
-- Narrativexempel: View: verifikat_rader
-- ============================================================================
-- Denormaliserad sammanslagning av verifikat + konteringar + konton, för att
-- enkelt kunna lista vad som hände i ett verifikat.

CREATE VIEW verifikat_rader AS
SELECT
  v.id, v.datum, v.beskrivning,
  k.konto, ko.namn AS konto_namn,
  k.debet, k.kredit
FROM verifikat v
JOIN konteringar k ON k.verifikat_id = v.id
JOIN konton ko ON ko.nummer = k.konto;


-- ============================================================================
-- Övning: View: resultaträkning
-- ============================================================================
-- En rad med tre kolumner: intäkter, kostnader och resultat (intäkter - kostnader).
-- Använder den cachade konton.saldo-kolumnen, så den förutsätter att triggern
-- ovan är aktiv (eller att cachen backfillats manuellt).

CREATE VIEW resultaträkning AS
SELECT
  (SELECT COALESCE(SUM(saldo), 0) FROM konton WHERE typ = 'intäkt')  AS intäkter,
  (SELECT COALESCE(SUM(saldo), 0) FROM konton WHERE typ = 'kostnad') AS kostnader,
  (SELECT COALESCE(SUM(saldo), 0) FROM konton WHERE typ = 'intäkt')
    - (SELECT COALESCE(SUM(saldo), 0) FROM konton WHERE typ = 'kostnad') AS resultat;


-- ============================================================================
-- Utforska vidare: View: balansräkning
-- ============================================================================
-- Tillgångar ska alltid vara lika med skulder + eget kapital. Det är vad
-- dubbel bokföring garanterar.

CREATE VIEW balansräkning AS
SELECT
  (SELECT COALESCE(SUM(saldo), 0) FROM konton WHERE typ = 'tillgång') AS tillgångar,
  (SELECT COALESCE(SUM(saldo), 0) FROM konton WHERE typ IN ('skuld', 'eget_kapital'))
    AS skulder_och_eget_kapital;


-- ============================================================================
-- Smoke test
-- ============================================================================
-- Förväntade saldon efter de tre anropen nedan:
--   1930 Bank                  3250.00   (5000 - 3000 + 1250)
--   2018 Egen insättning       5000.00
--   5011 Kontorshyra           3000.00
--   2610 Utgående moms          250.00
--   3001 Försäljning vara 25%  1000.00

CALL bokför('2026-01-15', 'Egen insättning', '1930', '2018', 5000);
CALL bokför('2026-01-16', 'Hyra januari',    '5011', '1930', 3000);
CALL bokför_försäljning('2026-01-17', 1250);

SELECT nummer, namn, saldo FROM konton WHERE saldo <> 0 ORDER BY nummer;

-- Verifiera att cache-kolumnen och saldo()-funktionen är överens
SELECT nummer, namn, saldo AS cache, saldo(nummer) AS från_konteringar
  FROM konton WHERE saldo <> 0 ORDER BY nummer;

-- Resultaträkning: intäkter 1000, kostnader 3000, resultat -2000
SELECT * FROM resultaträkning;

-- Balansräkning: tillgångar 3250 (Bank), skulder_och_eget_kapital 5250
-- (Egen insättning 5000 + Utgående moms 250). Differensen 2000 = periodens
-- förlust som inte är bokförd mot Eget kapital än. Den identiteten är vad
-- studenterna ska upptäcka i Utforska-vidare-uppgiften.
SELECT * FROM balansräkning;

-- verifikat_rader-vyn från narrativet: visa allt på en rad per kontering
SELECT * FROM verifikat_rader ORDER BY id, konto;
