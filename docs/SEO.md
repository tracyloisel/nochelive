# SEO de Noche Live

## Architecture

Le produit personnalisé (`/`, `/jugar`, profils, défis, sessions et consoles) n’est pas le site d’acquisition. Il reste accessible aux joueurs mais reçoit `noindex`. Les routes sensibles (`/p`, `/s`, fiches et défis) reçoivent `noindex, nofollow` ainsi qu’un en-tête `X-Robots-Tag`.

Le portail public utilise une URL propre à chaque langue :

- espagnol : `/es/...`
- français : `/fr/...`
- portugais du Brésil : `/pt-br/...`
- anglais : `/en/...`

Chaque page publique possède un titre, une description, une URL canonique, les quatre liens `hreflang`, un alternate `x-default`, Open Graph, Twitter Cards et des données structurées JSON-LD.

## Clusters publiés

Trois piliers sont reliés depuis chaque page d’accueil localisée : jeux bibliques, activités chrétiennes et étude biblique. Chaque pilier possède une page longue traîne : quiz biblique, activités pour jeunes et étude des Psaumes.

Les Écritures publiques ont trois niveaux crawlables : livre, chapitre et passage. Un passage accepte un verset ou une plage continue, ce qui donne aussi des liens de partage lisibles qui ouvrent directement la liseuse. Les corpus couverts sont la Bible complète (66 livres, 1 189 chapitres), le Livre de Mormon (15 livres, 239 chapitres) et Doctrine et Alliances (138 sections). Exemples :

- `/fr/bible/2-samuel/2/1`
- `/fr/bible/1-rois/21/2-3`
- `/fr/livre-de-mormon/moroni/10/4`
- `/fr/doctrine-et-alliances/sections/121/7`

Les pages chapitre relient tous leurs versets et les chapitres voisins. Les pages livre relient tous leurs chapitres. Le lecteur interne `/escrituras/...` reste une fonction du jeu et n’est pas indexé.

Les cinq pages de découverte de l’Église disposent également d’URLs traduites, par exemple `/fr/eglise-de-jesus-christ/croyances`, avec canonical et `hreflang` réciproques.

## Découverte

`/sitemap.xml` contient chaque URL canonique dans un élément `<loc>` distinct, ses alternates linguistiques, tous les livres et chapitres des trois corpus, les passages (y compris les plages continues) utilisés par le jeu, les pages Église et les pages publiques des assemblées. Les plages choisies librement par un lecteur restent crawlables et canoniques, sans gonfler artificiellement le sitemap avec toutes les combinaisons possibles. Il est mis en cache publiquement pendant une heure. `public/robots.txt` annonce le sitemap et bloque uniquement les espaces techniques ou privés.

## Découverte par les agents IA

`/llms.txt` fournit une carte Markdown concise des contenus publics dans les quatre langues. Chaque page d’acquisition possède une version Markdown sous `/agent/:locale/...md`; la page HTML l’annonce avec un en-tête HTTP `Link` (`rel="alternate"`) et référence `/llms.txt` avec `rel="describedby"`.

Ces fichiers améliorent la lecture à la demande par les agents compatibles, mais ne remplacent ni le sitemap, ni le HTML sémantique, ni `robots.txt`. Les versions Markdown n’exposent que le corpus éditorial public. Elles demandent explicitement une intention utilisateur avant toute action et omettent les sessions, consoles, profils et jetons de défi.

`OAI-SearchBot` et `ChatGPT-User` sont explicitement autorisés sur le contenu public et héritent des mêmes exclusions privées. La politique d’entraînement n’est pas redéfinie par une règle spécifique : elle reste celle du groupe générique `User-agent: *`.

## Mise en production

1. Déployer avec `APP_HOST` réglé sur le domaine canonique.
2. Vérifier que le domaine canonique est bien `nochelive.com`; mettre à jour la ligne `Sitemap:` de `public/robots.txt` seulement si ce domaine change.
3. Créer une propriété de domaine dans Google Search Console et Bing Webmaster Tools.
4. Définir `GOOGLE_SITE_VERIFICATION` dans l’environnement Render si Google demande une balise HTML.
5. Soumettre `https://DOMAINE/sitemap.xml`, puis demander en priorité l’indexation des quatre pages d’accueil, des trois piliers, de `/fr/bible/2-samuel/2/1` et des pages racines des trois corpus.
6. Valider dans l’inspection d’URL que le HTML rendu, la canonical et le `hreflang` correspondent ; cette étape externe ne peut pas être exécutée depuis le code local.

## Mesure

Suivre chaque semaine dans Search Console, séparément par langue, corpus et répertoire : impressions non-marque, clics, CTR, position médiane et pages indexées. Les CTA éditoriaux portent `utm_source=organic`, `utm_medium=seo` et un `utm_campaign` correspondant au cluster ; les accès aux pages d’acquisition et aux passages sont aussi journalisés côté serveur (`seo_landing`, `seo_scripture`). Dans l’analytics produit, segmenter les arrivées dont la page d’entrée commence par `/es`, `/fr`, `/pt-br` ou `/en`, puis mesurer le clic vers le jeu et la création d’une fiche.

Objectif principal : `impression organique → page éditoriale → clic Jouer → création de fiche`. Le trafic sans entrée dans l’aventure reste un signal secondaire.
