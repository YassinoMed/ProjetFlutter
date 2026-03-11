# Delegation Doctor <-> Secretary

## A. Vision métier

- Une secrétaire garde son identité propre: `users.role = SECRETARY`.
- Elle n'hérite jamais du rôle médecin. Elle agit dans une relation de délégation explicite vers un seul médecin dans la version simple.
- Chaque action sensible doit porter deux dimensions:
  - `actor_user_id`: la secrétaire réelle.
  - `acting_doctor_user_id`: le médecin au nom duquel l'action est exécutée.
- Le backend ne déduit jamais implicitement ce contexte: il exige `X-Acting-Doctor-Id` pour les routes déléguées.

Cas d'usage couverts:

- invitation d'une secrétaire par un médecin
- acceptation d'invitation avec création de compte
- attribution de permissions fines par relation
- accès secrétaire à l'agenda et aux rendez-vous du médecin uniquement si la délégation est active
- suspension, réactivation et révocation immédiates
- audit complet des actions de gestion et d'exploitation

## B. Modèle de données

### `users`

- `role` étendu avec `SECRETARY`
- conserve l'identité réelle de l'utilisateur

### `doctor_secretary_delegations`

- `id` UUID
- `doctor_user_id` FK -> `users.id`
- `secretary_user_id` FK nullable -> `users.id`
- `invited_by_user_id` FK -> `users.id`
- `revoked_by_user_id` FK nullable -> `users.id`
- `invited_email`
- `invited_first_name`
- `invited_last_name`
- `status`: `PENDING | ACTIVE | SUSPENDED | REVOKED`
- `activated_at_utc`, `suspended_at_utc`, `revoked_at_utc`, `last_used_at_utc`
- `suspension_reason`, `revocation_reason`
- `context_snapshot` JSON

Contraintes:

- `unique(doctor_user_id, invited_email)`
- index sur les statuts et dates d'usage

### `doctor_secretary_permissions`

- `id`
- `delegation_id` FK -> `doctor_secretary_delegations.id`
- `permission`
- `unique(delegation_id, permission)`

Permissions actuelles:

- `MANAGE_APPOINTMENTS`
- `MANAGE_SCHEDULE`
- `VIEW_PATIENT_DIRECTORY`
- `SEND_ADMIN_MESSAGES`
- `VIEW_ADMINISTRATIVE_DATA`

### `secretary_invitations`

- `id` UUID
- `delegation_id` FK
- `created_by_user_id` FK
- `email`
- `token_hash`
- `status`: `PENDING | ACCEPTED | EXPIRED | REVOKED`
- `expires_at_utc`, `accepted_at_utc`, `revoked_at_utc`

### `audit_logs`

Ajouts:

- `actor_role`
- `acting_doctor_user_id`
- `delegation_id`
- `ip_address`
- `user_agent`

## C. Règles d'autorisation

Le contrôle est à trois niveaux:

1. rôle global
   - `DOCTOR` ou `ADMIN` pour gérer les secrétaires
   - `SECRETARY` pour agir en délégation
2. relation de délégation
   - la délégation doit exister
   - elle doit lier la secrétaire réelle au médecin ciblé
   - son statut doit être `ACTIVE`
3. permission fine
   - vérifiée à chaque requête métier déléguée

Implémentation:

- `DoctorSecretaryDelegationPolicy`
- `ResolveDoctorDelegationContext`
- `DelegationContextService`

## D. Flux métier

### Invitation

1. le médecin appelle `POST /api/doctor/secretaries/invite`
2. Laravel crée une délégation `PENDING`
3. Laravel stocke les permissions accordées
4. Laravel crée une invitation horodatée avec `token_hash`
5. audit `secretary.invited`

### Acceptation

1. la secrétaire appelle `POST /api/secretary/invitations/accept`
2. le token est comparé via `Hash::check`
3. le compte secrétaire est créé ou recyclé si déjà secrétaire
4. la délégation passe à `ACTIVE`
5. l'invitation passe à `ACCEPTED`
6. audit `secretary.invitation.accepted`

### Exécution déléguée

1. le mobile choisit le médecin actif
2. appelle `POST /api/context/switch-doctor`
3. conserve `doctor_user_id`
4. envoie ensuite `X-Acting-Doctor-Id` sur chaque requête déléguée
5. le middleware résout la délégation
6. le service vérifie la permission fine
7. audit de l'action métier avec l'acteur réel et le médecin cible

## E. Backend Laravel

Points d'entrée:

- `POST /api/doctor/secretaries/invite`
- `GET /api/doctor/secretaries`
- `PATCH /api/doctor/secretaries/{delegationId}/permissions`
- `PATCH /api/doctor/secretaries/{delegationId}/suspend`
- `PATCH /api/doctor/secretaries/{delegationId}/reactivate`
- `DELETE /api/doctor/secretaries/{delegationId}`
- `POST /api/secretary/invitations/accept`
- `GET /api/me/delegations`
- `POST /api/context/switch-doctor`

Classes critiques:

- `App\Services\DoctorSecretaries\DoctorSecretaryService`
- `App\Services\DelegationContextService`
- `App\Http\Middleware\ResolveDoctorDelegationContext`
- `App\Http\Controllers\Api\DoctorSecretaryController`
- `App\Http\Controllers\Api\SecretaryInvitationController`
- `App\Http\Controllers\Api\DelegationContextController`

Routes déjà protégées par contexte:

- `/api/schedule`
- `/api/appointments`

## F. Frontend Flutter

Pattern retenu:

- modèles dédiés pour délégations et permissions
- datasource Dio
- repository léger
- providers Riverpod
- une page médecin de gestion des secrétaires
- une page secrétaire avec bannière "Vous agissez pour le compte du Dr X"

Le contexte actif est stocké localement dans un provider et propagé via l'en-tête `X-Acting-Doctor-Id`.

## G. Audit et sécurité

- toutes les actions de gestion sont loguées
- toutes les actions déléguées conservent l'identité réelle
- révocation/suspension immédiates car le backend relit la délégation active à chaque requête
- protection IDOR via policies + matching strict `doctor_user_id`
- pas de fusion d'identité médecin/secrétaire
- token d'invitation stocké uniquement sous forme hashée

## H. Cas de test

- invitation puis acceptation d'une secrétaire
- consultation d'agenda et rendez-vous par secrétaire avec contexte valide
- suspension puis refus immédiat d'accès
- accès refusé si absence de `X-Acting-Doctor-Id`
- accès refusé si permission non accordée
- accès refusé sur délégation d'un autre médecin

## I. Limites et hypothèses

- la première version attache une secrétaire à un médecin actif à la fois côté usage
- l'extension multi-médecins est déjà possible au niveau données via plusieurs délégations
- la messagerie administrative au nom du médecin n'est pas encore branchée sur les conversations
- les actions cliniques restent interdites par défaut et doivent avoir leurs propres permissions si un jour elles sont ouvertes
