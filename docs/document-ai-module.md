# Module IA Documents Médicaux

## A. Architecture globale

Flux v1:

1. Flutter envoie le fichier via `POST /api/documents/upload`
2. Flutter pré-analyse les images avec ML Kit OCR et un contrôle qualité local
3. Laravel valide le type, la taille, le contexte patient/médecin
4. le fichier est stocké sur un disque privé
5. un enregistrement `documents` passe à `PENDING`
6. `ProcessDocumentJob` orchestre:
   - extraction texte native si possible
   - OCR si image ou PDF scanné et moteur disponible
   - fallback OCR mobile si l’OCR serveur n’est pas disponible
   - normalisation du texte
   - analyse structurée heuristique ou provider IA HTTP configuré
   - génération des résumés
   - extraction des entités
   - classification et tags
7. Flutter suit les statuts `pending / processing / completed / failed`

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
- `application/pdf` scanné -> conversion `pdftoppm` puis OCR `tesseract`
- `image/*` -> OCR `tesseract` si disponible, sinon texte OCR mobile ML Kit si fourni

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

- `DOCUMENTS_AI_DRIVER=http` pour utiliser un provider LLM compatible chat-completions ou l'API médicale `II-Medical-8B`
- prompts JSON stricts
- garde-fous anti-hallucinations
- fallback automatique vers l’analyse heuristique si le provider IA échoue
- `POST /api/documents/{id}/ask` peut utiliser `/chat` du provider IA pour le chat documentaire, avec fallback grounded local

### Fallback

- si aucun extracteur n’est disponible -> `FAILED`
- si OCR renvoie vide -> `FAILED`
- si l’analyse n’a pas assez d’éléments -> résumés prudents + champs `missing_information`
- si ML Kit fournit un texte OCR mobile -> seed d’extraction `client_ocr`, sans texte en clair dans `source_metadata`

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
- `HttpDocumentAiAnalyzer`
- `HttpDocumentQuestionAnswerer`
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
- OCR local ML Kit sur images `jpg/png/webp`
- score qualité image avant upload: résolution, luminosité, contraste, flou

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
- pas de texte OCR brut dans `source_metadata`
- métadonnées qualité image limitées au score, dimensions et avertissements non médicaux
- provider IA externe désactivé par défaut et activable uniquement par variables d’environnement
- l'API IA externe reçoit uniquement le texte extrait du document quand `DOCUMENTS_AI_DRIVER=http`; vérifier la conformité contractuelle avant production
- le texte brut des questions utilisateur n'est pas journalisé: seuls hash, longueur et statut de preuve insuffisante sont stockés
- erreurs sanitizées
- audit des uploads, suppressions, réanalyses et traitements

Variables utiles:

- `DOCUMENTS_OCR_DRIVER=tesseract`
- `DOCUMENTS_OCR_LANGUAGES=fra+eng`
- `DOCUMENTS_PDF_OCR_MAX_PAGES=3`
- `DOCUMENTS_AI_DRIVER=heuristic|http`
- `DOCUMENTS_DOCUMENT_CHAT_DRIVER=heuristic|http`
- `DOCUMENTS_AI_PROVIDER=medical_api|openai_compatible`
- `DOCUMENTS_AI_BASE_URL=https://d672cc7a-3627-49c3-ae0c-7b3e611ee41e.notebook.gra.ai.cloud.ovh.net/proxy/8097`
- `DOCUMENTS_AI_API_KEY=`
- `DOCUMENTS_AI_MODEL=II-Medical-8B`
- `DOCUMENTS_AI_GENERATE_PATH=/generate`
- `DOCUMENTS_AI_CHAT_PATH=/chat`
- `DOCUMENTS_AI_MAX_NEW_TOKENS=1024`
- `DOCUMENTS_AI_TEMPERATURE=0`

Exemple d'activation pour staging:

```env
DOCUMENTS_AI_DRIVER=http
DOCUMENTS_DOCUMENT_CHAT_DRIVER=http
DOCUMENTS_AI_PROVIDER=medical_api
DOCUMENTS_AI_BASE_URL=https://d672cc7a-3627-49c3-ae0c-7b3e611ee41e.notebook.gra.ai.cloud.ovh.net/proxy/8097
DOCUMENTS_AI_MODEL=II-Medical-8B
DOCUMENTS_AI_GENERATE_PATH=/generate
DOCUMENTS_AI_CHAT_PATH=/chat
DOCUMENTS_AI_TEMPERATURE=0
```

## I. Tests

À couvrir:

- upload valide
- autorisation stricte
- stockage des métadonnées ML Kit et qualité image
- traitement réussi avec extracteur/analyzer simulés
- document vide ou illisible
- réanalyse

## J. Limites et hypothèses

- v1 ne fait pas encore d’index sémantique complet
- v1 dépend de binaires système pour `pdftotext`, `pdftoppm` et `tesseract`
- sans moteur OCR/LLM configuré, le pipeline reste utilisable mais limité
