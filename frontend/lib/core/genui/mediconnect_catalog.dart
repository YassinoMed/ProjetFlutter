/// GenUI Widget Catalog for MediConnect Pro
/// Définit les widgets que Gemini peut utiliser pour générer des UI dynamiques
library;

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../shared/widgets/clinical_ui.dart';
import '../theme/app_theme.dart';

/// Catalogue de widgets MediConnect pour GenUI.
/// Les widgets utilisent le design system existant (ClinicalSurface, AppTheme).
class MediConnectCatalog {
  MediConnectCatalog._();

  static Catalog get catalog => Catalog(
        [
          appointmentCard,
          patientInfoCard,
          medicalForm,
          statusBadge,
          actionButton,
          dataTableItem,
          checklist,
          alertCard,
          metricCard,
        ],
        catalogId: 'com.mediconnect.catalog',
        systemPromptFragments: const [
          "Utilise ces widgets pour générer l'UI. Préfère toujours un widget "
              'visuel à du texte brut pour présenter des informations '
              'médicales.',
        ],
      );

  // ══════════════════════════════════════════════════════════
  // ── Carte de rendez-vous ──────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final appointmentCard = CatalogItem(
    name: 'AppointmentCard',
    dataSchema: S.object(
      properties: {
        'doctorName': S.string(description: 'Nom du médecin'),
        'specialty': S.string(description: 'Spécialité médicale'),
        'date': S.string(description: 'Date du RDV (format: dd/MM/yyyy)'),
        'time': S.string(description: 'Heure du RDV (format: HH:mm)'),
        'status': S.string(
          description: 'Statut: confirmed, pending, cancelled',
        ),
        'type': S.string(
          description: 'Type: consultation, teleconsultation',
        ),
      },
      required: ['doctorName', 'date', 'time', 'status'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final doctorName = json['doctorName'] as String? ?? '';
      final specialty = json['specialty'] as String? ?? '';
      final date = json['date'] as String? ?? '';
      final time = json['time'] as String? ?? '';
      final status = json['status'] as String? ?? 'pending';
      final type = json['type'] as String? ?? 'consultation';

      final statusColor = switch (status) {
        'confirmed' => AppTheme.successColor,
        'cancelled' => AppTheme.errorColor,
        _ => AppTheme.warningColor,
      };

      final statusLabel = switch (status) {
        'confirmed' => 'Confirmé',
        'cancelled' => 'Annulé',
        _ => 'En attente',
      };

      return ClinicalSurface(
        onTap: () => ctx.dispatchEvent(
          UserActionEvent(
            surfaceId: ctx.surfaceId,
            sourceComponentId: ctx.id,
            name: 'appointmentTapped',
            context: {'appointmentId': ctx.id},
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClinicalAvatar(name: doctorName, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctorName, style: AppTheme.titleSmall),
                      if (specialty.isNotEmpty)
                        Text(specialty, style: AppTheme.bodySmall),
                    ],
                  ),
                ),
                ClinicalStatusChip(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppTheme.neutralGray500,
                ),
                const SizedBox(width: 6),
                Text('$date à $time', style: AppTheme.bodyMedium),
                const Spacer(),
                Icon(
                  type == 'teleconsultation'
                      ? Icons.videocam
                      : Icons.location_on,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  type == 'teleconsultation' ? 'Vidéo' : 'Cabinet',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Carte info patient ────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final patientInfoCard = CatalogItem(
    name: 'PatientInfoCard',
    dataSchema: S.object(
      properties: {
        'name': S.string(description: 'Nom complet du patient'),
        'age': S.integer(description: 'Âge du patient'),
        'bloodType': S.string(description: 'Groupe sanguin'),
        'allergies': S.list(
          items: S.string(),
          description: 'Liste des allergies',
        ),
        'currentMedications': S.list(
          items: S.string(),
          description: 'Médicaments en cours',
        ),
      },
      required: ['name'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final name = json['name'] as String? ?? '';
      final age = json['age'] as int?;
      final bloodType = json['bloodType'] as String?;
      final allergies = (json['allergies'] as List?)?.cast<String>() ?? [];
      final medications =
          (json['currentMedications'] as List?)?.cast<String>() ?? [];

      return ClinicalSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClinicalAvatar(name: name, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTheme.titleMedium),
                      if (age != null)
                        Text('$age ans', style: AppTheme.bodySmall),
                    ],
                  ),
                ),
                if (bloodType != null)
                  ClinicalStatusChip(
                    label: bloodType,
                    color: AppTheme.errorColor,
                    icon: Icons.water_drop,
                  ),
              ],
            ),
            if (allergies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Allergies', style: AppTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: allergies
                    .map((a) => ClinicalStatusChip(
                          label: a,
                          color: AppTheme.warningColor,
                          compact: true,
                        ))
                    .toList(),
              ),
            ],
            if (medications.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Traitements en cours', style: AppTheme.labelLarge),
              const SizedBox(height: 4),
              ...medications.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medication,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(m, style: AppTheme.bodySmall)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Formulaire médical dynamique ──────────────────────────
  // ══════════════════════════════════════════════════════════

  static final medicalForm = CatalogItem(
    name: 'MedicalForm',
    dataSchema: S.object(
      properties: {
        'title': S.string(description: 'Titre du formulaire'),
        'fields': S.list(
          items: S.object(properties: {
            'label': S.string(description: 'Label du champ'),
            'key': S.string(description: 'Clé unique du champ'),
            'type': S.string(
              description: 'Type: text, number, date, textarea',
            ),
            'required': S.boolean(description: 'Champ obligatoire'),
            'placeholder': S.string(description: 'Placeholder du champ'),
          }),
          description: 'Liste des champs du formulaire',
        ),
        'submitLabel': S.string(
          description: 'Texte du bouton de soumission',
        ),
      },
      required: ['title', 'fields'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final title = json['title'] as String? ?? 'Formulaire';
      final fields =
          (json['fields'] as List?)?.cast<Map<String, Object?>>() ?? [];
      final submitLabel = json['submitLabel'] as String? ?? 'Envoyer';

      return ClinicalSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleMedium),
            const SizedBox(height: 16),
            ...fields.map((field) {
              final label = field['label'] as String? ?? '';
              final key = field['key'] as String? ?? '';
              final type = field['type'] as String? ?? 'text';
              final placeholder = field['placeholder'] as String?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: placeholder ?? 'Saisir $label',
                  ),
                  keyboardType: type == 'number'
                      ? TextInputType.number
                      : type == 'textarea'
                          ? TextInputType.multiline
                          : TextInputType.text,
                  maxLines: type == 'textarea' ? 4 : 1,
                  onChanged: (value) {
                    ctx.dispatchEvent(
                      UserActionEvent(
                        surfaceId: ctx.surfaceId,
                        sourceComponentId: ctx.id,
                        name: 'fieldChanged',
                        context: {'key': key, 'value': value},
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ctx.dispatchEvent(
                  UserActionEvent(
                    surfaceId: ctx.surfaceId,
                    sourceComponentId: ctx.id,
                    name: 'formSubmit',
                    context: {'formId': ctx.id},
                  ),
                ),
                child: Text(submitLabel),
              ),
            ),
          ],
        ),
      );
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Badge de statut ───────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final statusBadge = CatalogItem(
    name: 'StatusBadge',
    dataSchema: S.object(
      properties: {
        'label': S.string(description: 'Texte du badge'),
        'type': S.string(
          description: 'Type: success, warning, error, info',
        ),
      },
      required: ['label', 'type'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final label = json['label'] as String? ?? '';
      final type = json['type'] as String? ?? 'info';

      final color = switch (type) {
        'success' => AppTheme.successColor,
        'warning' => AppTheme.warningColor,
        'error' => AppTheme.errorColor,
        _ => AppTheme.infoColor,
      };

      return ClinicalStatusChip(label: label, color: color);
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Bouton d'action ───────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final actionButton = CatalogItem(
    name: 'ActionButton',
    dataSchema: S.object(
      properties: {
        'label': S.string(description: 'Texte du bouton'),
        'action': S.string(description: "Identifiant de l'action"),
        'variant': S.string(
          description: 'Variante: primary, outlined, text',
        ),
      },
      required: ['label', 'action'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final label = json['label'] as String? ?? '';
      final action = json['action'] as String? ?? '';
      final variant = json['variant'] as String? ?? 'primary';

      void onPressed() {
        ctx.dispatchEvent(
          UserActionEvent(
            surfaceId: ctx.surfaceId,
            sourceComponentId: ctx.id,
            name: 'buttonAction',
            context: {'action': action},
          ),
        );
      }

      return switch (variant) {
        'outlined' => OutlinedButton(
            onPressed: onPressed,
            child: Text(label),
          ),
        'text' => TextButton(onPressed: onPressed, child: Text(label)),
        _ => ElevatedButton(onPressed: onPressed, child: Text(label)),
      };
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Tableau de données ────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final dataTableItem = CatalogItem(
    name: 'DataTable',
    dataSchema: S.object(
      properties: {
        'title': S.string(description: 'Titre du tableau'),
        'columns': S.list(
          items: S.string(),
          description: 'Noms des colonnes',
        ),
        'rows': S.list(
          items: S.list(items: S.string()),
          description: 'Lignes de données (tableau de tableaux de strings)',
        ),
      },
      required: ['columns', 'rows'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final title = json['title'] as String?;
      final columns = (json['columns'] as List?)?.cast<String>() ?? [];
      final rows = (json['rows'] as List?)
              ?.map((r) => (r as List).cast<String>())
              .toList() ??
          [];

      return ClinicalSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: AppTheme.titleSmall),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns
                    .map((c) => DataColumn(
                          label: Text(c, style: AppTheme.labelLarge),
                        ))
                    .toList(),
                rows: rows
                    .map((row) => DataRow(
                          cells:
                              row.map((cell) => DataCell(Text(cell))).toList(),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Checklist ─────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final checklist = CatalogItem(
    name: 'Checklist',
    dataSchema: S.object(
      properties: {
        'title': S.string(description: 'Titre de la checklist'),
        'items': S.list(
          items: S.object(properties: {
            'label': S.string(description: "Texte de l'item"),
            'checked': S.boolean(description: 'Coché ou non'),
          }),
          description: 'Items de la checklist',
        ),
      },
      required: ['title', 'items'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final title = json['title'] as String? ?? '';
      final items =
          (json['items'] as List?)?.cast<Map<String, Object?>>() ?? [];

      return ClinicalSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleSmall),
            const SizedBox(height: 8),
            ...items.asMap().entries.map((entry) {
              final item = entry.value;
              final label = item['label'] as String? ?? '';
              final checked = item['checked'] as bool? ?? false;

              return CheckboxListTile(
                value: checked,
                title: Text(label, style: AppTheme.bodyMedium),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  ctx.dispatchEvent(
                    UserActionEvent(
                      surfaceId: ctx.surfaceId,
                      sourceComponentId: ctx.id,
                      name: 'checkToggle',
                      context: {
                        'index': entry.key,
                        'checked': value ?? false,
                      },
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Carte d'alerte ────────────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final alertCard = CatalogItem(
    name: 'AlertCard',
    dataSchema: S.object(
      properties: {
        'title': S.string(description: "Titre de l'alerte (optionnel)"),
        'message': S.string(description: "Message de l'alerte"),
        'severity': S.string(
          description: 'Sévérité: info, warning, error, success',
        ),
      },
      required: ['message', 'severity'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final title = json['title'] as String?;
      final message = json['message'] as String? ?? '';
      final severity = json['severity'] as String? ?? 'info';

      final (color, icon) = switch (severity) {
        'error' => (AppTheme.errorColor, Icons.error_outline),
        'warning' => (AppTheme.warningColor, Icons.warning_amber_rounded),
        'success' => (AppTheme.successColor, Icons.check_circle_outline),
        _ => (AppTheme.infoColor, Icons.info_outline),
      };

      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.softColor(color),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: AppTheme.titleSmall.copyWith(color: color),
                    ),
                  if (title != null) const SizedBox(height: 4),
                  Text(message, style: AppTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  // ══════════════════════════════════════════════════════════
  // ── Carte métrique (KPI) ──────────────────────────────────
  // ══════════════════════════════════════════════════════════

  static final metricCard = CatalogItem(
    name: 'MetricCard',
    dataSchema: S.object(
      properties: {
        'label': S.string(description: 'Label de la métrique'),
        'value': S.string(description: 'Valeur principale'),
        'unit': S.string(description: 'Unité (optionnel)'),
        'trend': S.string(
          description: 'Tendance: up, down, stable (optionnel)',
        ),
        'color': S.string(
          description: 'Couleur: primary, success, warning, error',
        ),
      },
      required: ['label', 'value'],
    ),
    widgetBuilder: (ctx) {
      final json = ctx.data as Map<String, Object?>;
      final label = json['label'] as String? ?? '';
      final value = json['value'] as String? ?? '';
      final unit = json['unit'] as String?;
      final trend = json['trend'] as String?;
      final colorName = json['color'] as String? ?? 'primary';

      final color = switch (colorName) {
        'success' => AppTheme.successColor,
        'warning' => AppTheme.warningColor,
        'error' => AppTheme.errorColor,
        _ => AppTheme.primaryColor,
      };

      final trendIcon = switch (trend) {
        'up' => Icons.trending_up,
        'down' => Icons.trending_down,
        _ => null,
      };

      return ClinicalSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.neutralGray400,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTheme.headlineMedium.copyWith(color: color),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(unit, style: AppTheme.bodySmall),
                  ),
                ],
                const Spacer(),
                if (trendIcon != null)
                  Icon(
                    trendIcon,
                    color: trend == 'up'
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    size: 20,
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
