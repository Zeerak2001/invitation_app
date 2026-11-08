import 'template_def.dart';
import 'wedding_classic.dart';
import 'corporate_modern.dart';

/// Add a new template here and it automatically shows up in the picker
/// with its own generated form.
final List<TemplateDef> kTemplates = [
  weddingClassic,
  corporateModern,
];

List<String> get kCategories =>
    kTemplates.map((t) => t.category).toSet().toList();
