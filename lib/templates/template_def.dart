import 'package:flutter/widgets.dart';

/// Every card is laid out at this logical size (5:7 ratio, like a 5x7in card).
const Size kCardSize = Size(350, 490);

/// How the editor collects a field's value.
enum FieldType { text, date, time, location }

class FieldDef {
  final String key;
  final String label;
  final bool multiline;
  final String initial;
  final FieldType type;

  /// Only used when [type] is [FieldType.date] (intl DateFormat pattern).
  final String dateFormat;

  const FieldDef(
    this.key,
    this.label, {
    this.multiline = false,
    this.initial = '',
    this.type = FieldType.text,
    this.dateFormat = 'EEEE, d MMMM yyyy',
  });
}

class TemplateDef {
  final String id;
  final String name;
  final String category;
  final List<FieldDef> fields;
  final Widget Function(Map<String, String> data) builder;

  const TemplateDef({
    required this.id,
    required this.name,
    required this.category,
    required this.fields,
    required this.builder,
  });
}
