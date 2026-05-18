import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/ai_document_analysis_service.dart';

final aiDocumentAnalysisServiceProvider =
    Provider<AiDocumentAnalysisService>((ref) {
  return const AiDocumentAnalysisService();
});
