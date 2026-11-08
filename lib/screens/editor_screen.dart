import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/export_service.dart';
import '../services/location_picker.dart';
import '../services/snackbar.dart';
import '../templates/template_def.dart';

const _dark = Color(0xFF222222);
const _bg = Color(0xFFF6F6F6);

class EditorScreen extends StatefulWidget {
  final TemplateDef template;
  const EditorScreen({super.key, required this.template});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _cardKey = GlobalKey();
  late final Map<String, TextEditingController> _controllers;
  final Map<String, DateTime> _dates = {};
  final Map<String, TimeOfDay> _times = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final f in widget.template.fields)
        f.key: TextEditingController(text: f.initial),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _data => {
    for (final e in _controllers.entries) e.key: e.value.text,
  };

  Widget _pickerTheme(BuildContext context, Widget? child) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: _dark,
          onPrimary: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickDate(FieldDef f) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dates[f.key] ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      builder: _pickerTheme,
    );
    if (d == null) return;
    _dates[f.key] = d;
    setState(
      () => _controllers[f.key]!.text = DateFormat(f.dateFormat).format(d),
    );
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _pickTime(FieldDef f) async {
    final t = await showTimePicker(
      context: context,
      initialTime: _times[f.key] ?? const TimeOfDay(hour: 19, minute: 0),
      builder: _pickerTheme,
    );
    if (t == null) return;
    _times[f.key] = t;
    setState(() => _controllers[f.key]!.text = _fmtTime(t));
  }

  Future<void> _pickLocation(FieldDef f) async {
    final label = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (label == null || label.isEmpty) return;
    setState(() => _controllers[f.key]!.text = label);
  }

  /// SAVES
  Future<void> _export(bool pdf) async {
    setState(() => _busy = true);
    try {
      final png = await ExportService.capturePng(_cardKey);
      final String msg;
      if (pdf) {
        final pdfBytes = await ExportService.pngToPdf(png);
        msg = await ExportService.savePdf(pdfBytes);
      } else {
        msg = await ExportService.savePng(png);
      }
      if (mounted) {
        showAppSnack(context, msg, error: msg.toLowerCase().contains('denied'));
      }
    } catch (e) {
      if (mounted) showAppSnack(context, 'Export failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: _dark,
              ),
            ),
          ),
        ),
        title: Text(
          widget.template.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 110 + bottomInset),
            children: [
              // Rounded + shadow are OUTSIDE the RepaintBoundary, so the
              // exported PNG/PDF stays a clean full rectangle.
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AspectRatio(
                        aspectRatio: kCardSize.width / kCardSize.height,
                        child: FittedBox(
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: SizedBox.fromSize(
                              size: kCardSize,
                              child: widget.template.builder(_data),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Your details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              for (final f in widget.template.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _field(f),
                ),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomInset + 12,
            child: _actionBar(),
          ),
        ],
      ),
    );
  }

  Widget _field(FieldDef f) {
    final isDate = f.type == FieldType.date;
    final isTime = f.type == FieldType.time;
    final isLocation = f.type == FieldType.location;
    final pickerOnly = isDate || isTime; // location text stays editable

    VoidCallback? open;
    IconData? icon;
    if (isDate) {
      open = () => _pickDate(f);
      icon = Icons.calendar_today_outlined;
    } else if (isTime) {
      open = () => _pickTime(f);
      icon = Icons.schedule;
    } else if (isLocation) {
      open = () => _pickLocation(f);
      icon = Icons.map_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controllers[f.key],
        readOnly: pickerOnly,
        showCursor: !pickerOnly,
        onTap: pickerOnly ? open : null,
        minLines: 1,
        maxLines: f.multiline ? 4 : 1,
        cursorColor: _dark,
        decoration: InputDecoration(
          labelText: f.label,
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(
            color: _dark,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: icon == null
              ? null
              : IconButton(
                  icon: Icon(icon, color: _dark),
                  onPressed: open,
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: _dark, width: 1.5),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _actionBar() => Container(
    height: 68,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _dark,
      borderRadius: BorderRadius.circular(40),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(60),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: _busy
        ? const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          )
        : Row(
            children: [
              Expanded(
                child: _barButton(
                  icon: Icons.download,
                  label: 'Save PNG',
                  filled: true,
                  onTap: () => _export(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _barButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Save PDF',
                  filled: false,
                  onTap: () => _export(true),
                ),
              ),
            ],
          ),
  );

  Widget _barButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final fg = filled ? _dark : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: filled ? null : Border.all(color: Colors.white38),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
