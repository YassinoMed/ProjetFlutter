# Module IA Documents Médicaux

## A. Architecture globale

Flux v1:

1. Flutter envoie le fichier via `POST /api/documents/upload`
2. Laravel valide le type, la taille, le contexte patient/médecin
3. le fichier est stocké sur un disque privé
4. un enregistrement `documents` passe à `PENDING`
5. `ProcessDocumentJob` orchestre:
   - extraction texte native si possible
   - OCR si image scannée et moteur disponible
   - normalisation du texte
   - analyse structurée
   - génération des résumés
   - extraction des entités
   - classification et tags
6. Flutter suit les statuts `pending / processing / completed / failed`

Composants:

- `documents`: source de vérité du fichier et du statut global
- `document_extractions`: texte extrait, versionné et chiffré en base
- `document_summaries`: résumés multi-profils, versionnés et chiffrés
- `document_entities`: entités structurées, chiffrées
- `document_tags`: tags indexables pour recherche simple

## B. Modèle de données

Tables v1:

- `documents`
- `document_extractions`
- `document_summaries`
- `document_entities`
- `document_tags`

Pas de `document_versions` dédiée en v1: la version est portée par `document_extractions`, `document_summaries` et `document_entities`.

## C. Pipeline de traitement

### Détection

- `text/plain` -> lecture native
- `application/pdf` -> extraction CLI `pdftotext` si disponible
- `image/*` -> OCR `tesseract` si disponible

### Nettoyage

- trim
- normalisation des espaces
- conservation du texte brut et du texte normalisé

### Analyse

Version simple:

- classifieur heuristique non génératif
- extraction regex/keywords des champs connus
- résumés dérivés uniquement des faits détectés

Version avancée:

- adaptateur LLM compatible OpenAI
- prompts JSON stricts
- garde-fous anti-hallucinations

### Fallback

- si aucun extracteur n’est disponible -> `FAILED`
- si OCR renvoie vide -> `FAILED`
- si l’analyse n’a pas assez d’éléments -> résumés prudents + champs `missing_information`

## D. Backend Laravel

Endpoints:

- `POST /documents/upload`
- `GET /documents`
- `GET /documents/{id}`
- `GET /documents/{id}/summary`
- `GET /documents/{id}/entities`
- `POST /documents/{id}/reanalyze`
- `DELETE /documents/{id}`

Services:

- `DocumentStorageService`
- `CompositeDocumentTextExtractor`
- `HeuristicDocumentAiAnalyzer`
- `DocumentAnalysisPipeline`

## E. Frontend Flutter

Écrans v1:

- upload
- liste
- détail
- résumés
- entités
- réanalyse
- recherche simple par titre/type/tag

## F. Prompts IA internes

Implémentés dans `App\Services\Documents\Prompts\DocumentPromptFactory`.

Prompts fournis:

- extraction structurée
- résumé court
- résumé patient vulgarisé
- résumé professionnel
- éléments critiques
- classification

## G. Recherche / RAG

Version simple:

- filtre et recherche par `title`, `document_type`, `tags`

Version avancée:

- index sémantique par chunks
- embeddings stockés séparément
- QA bornée aux documents autorisés
- citations des passages sources

## H. Sécurité

- contrôle d’accès par `DocumentPolicy`
- stockage privé
- texte extrait et résumés chiffrés en base
- erreurs sanitizées
- audit des uploads, suppressions, réanalyses et traitements

## I. Tests

À couvrir:

- upload valide
- autorisation stricte
- traitement réussi avec extracteur/analyzer simulés
- document vide ou illisible
- réanalyse

## J. Limites et hypothèses

- v1 ne fait pas encore d’index sémantique complet
- v1 dépend de binaires système pour `pdftotext` / `tesseract`
- sans moteur OCR/LLM configuré, le pipeline reste utilisable mais limité
