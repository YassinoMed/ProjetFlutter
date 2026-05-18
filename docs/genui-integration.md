# Intégration GenUI SDK

## Structure recommandée

- `frontend/lib/core/genui/genui_service.dart` : orchestration SDK (`SurfaceController`, `Conversation`, `PromptBuilder`).
- `frontend/lib/core/genui/laravel_transport.dart` : transport backend sécurisé, parsing SSE, erreurs A2UI et cache mémoire.
- `frontend/lib/core/genui/mediconnect_catalog.dart` : catalogue unique MediConnect + widgets SDK de base.
- `frontend/lib/core/genui/system_prompts.dart` : règles médicales, RGPD, rôles et actions applicatives.
- `frontend/lib/core/genui/genui_providers.dart` : état Riverpod par session GenUI.
- `frontend/lib/core/genui/genui_prompt_panel.dart` : panneau réutilisable, rendu des surfaces et `ActionDelegate`.
- `backend/app/Http/Controllers/Api/GeminiController.php` : proxy Gemini texte et GenUI SSE.

## Fonctionnalités SDK disponibles

- `Catalog` / `CatalogItem` : utilisé pour les composants métier MediConnect.
- `BasicCatalogItems` : fusionné au catalogue pour les layouts (`Column`, `Row`, `Text`, `Tabs`, `TextField`, `Button`, médias, etc.).
- `PromptBuilder.custom` : utilisé avec `SurfaceOperations.all(dataModel: true)`.
- `SurfaceController` : cycle de vie des surfaces, événements UI et data model.
- `Conversation` : pont transport ↔ surfaces, événements loading/content/errors.
- `A2uiTransportAdapter` : parsing des chunks LLM en messages A2UI.
- `Surface` : rendu Flutter des surfaces dynamiques.
- `UserActionEvent` / `ActionDelegate` : actions UI vers navigation app ou retour modèle.
- `FallbackWidget` : fallback SDK conservé, complété par erreurs `AlertCard`.
- `CatalogView` : outil de dev disponible mais non branché en production.

## Où GenUI est intégré

- Authentification : login, inscription, appareils de confiance.
- Profil et paramètres : profil, RGPD/confidentialité.
- Messagerie : liste de conversations, détail de chat, assistant IA médecin.
- Écrans principaux : home patient, médecin et secrétaire.

## Utilisation

```dart
GenUiPromptPanel(
  sessionId: 'patient-home-$userId',
  role: user.role,
  title: 'Brief santé',
  prompt: 'Génère un brief patient avec MetricCard, Checklist et ActionButton.',
  contextData: {
    'screen': 'patient_home',
    'nextAppointments': appointments,
  },
)
```

Bonnes pratiques :

- Ne jamais appeler Gemini directement depuis Flutter pour GenUI.
- Envoyer un contexte minimal, utile et non sensible.
- Laisser `cache: true` pour les panneaux statiques; utiliser `cache: false` pour chat/réponse patient.
- Utiliser les actions supportées dans `ActionButton.action` : `appointments`, `chat`, `profile`, `gdpr`, `devices`, `notifications`, `records`, `documents`, `doctorSearch`, `bookAppointment`, `aiChat`.
- Garder les prompts métier dans `system_prompts.dart`, pas dans les widgets.
