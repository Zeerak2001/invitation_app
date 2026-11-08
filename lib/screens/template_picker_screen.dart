import 'package:flutter/material.dart';

import '../services/snackbar.dart';
import '../templates/template_def.dart';
import '../templates/template_registry.dart';
import 'editor_screen.dart';

const _dark = Color(0xFF222222);
const _bg = Color(0xFFF6F6F6);

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  final _pc = PageController(viewportFraction: 0.8);
  final _search = TextEditingController();
  final Set<String> _favorites = {};
  String? _category;
  int _tab = 0;

  @override
  void dispose() {
    _pc.dispose();
    _search.dispose();
    super.dispose();
  }

  List<TemplateDef> get _list {
    final q = _search.text.trim().toLowerCase();
    return kTemplates.where((t) {
      if (_tab == 1 && !_favorites.contains(t.id)) return false;
      if (_category != null && t.category != _category) return false;
      if (q.isNotEmpty &&
          !t.name.toLowerCase().contains(q) &&
          !t.category.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _resetPage() {
    if (_pc.hasClients) _pc.jumpToPage(0);
  }

  void _open(TemplateDef t) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EditorScreen(template: t)),
  );

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 18),
                _searchRow(),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Template Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                _chips(),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 100 + bottomInset),
                    child: list.isEmpty
                        ? const Center(
                            child: Text(
                              'No templates found',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : PageView.builder(
                            controller: _pc,
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final t = list[i];
                              return AnimatedBuilder(
                                animation: _pc,
                                builder: (_, child) {
                                  double page = 0;
                                  if (_pc.hasClients &&
                                      _pc.position.haveDimensions) {
                                    page = _pc.page ?? 0;
                                  }
                                  final delta = (page - i).abs().clamp(
                                    0.0,
                                    1.0,
                                  );
                                  return Transform.scale(
                                    scale: 1 - delta * 0.08,
                                    child: child,
                                  );
                                },
                                child: _TemplateCard(
                                  template: t,
                                  isFavorite: _favorites.contains(t.id),
                                  onFavorite: () => setState(() {
                                    _favorites.contains(t.id)
                                        ? _favorites.remove(t.id)
                                        : _favorites.add(t.id);
                                  }),
                                  onOpen: () => _open(t),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomInset + 12,
            child: _bottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create an invitation',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(
                'Pick a template to get started',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFEAE4F2),
          child: Icon(Icons.person, color: _dark),
        ),
      ],
    ),
  );

  Widget _searchRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(_resetPage),
              decoration: const InputDecoration(
                hintText: 'Search template name....',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chips() => SizedBox(
    height: 42,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [_chip('All', null), for (final c in kCategories) _chip(c, c)],
    ),
  );

  Widget _chip(String label, String? value) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() {
          _category = value;
          _resetPage();
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: selected ? _dark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? _dark : const Color(0xFFE4E4E4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    Widget item(int index, IconData icon, VoidCallback onTap) {
      final selected = _tab == index;
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: selected ? _dark : Colors.white),
        ),
      );
    }

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          item(
            0,
            Icons.home_rounded,
            () => setState(() {
              _tab = 0;
              _resetPage();
            }),
          ),
          item(
            1,
            Icons.favorite_border,
            () => setState(() {
              _tab = 1;
              _resetPage();
            }),
          ),
          item(2, Icons.folder_open, () {
            showAppSnack(context, 'Save Drafts Coming soon.', error: true);
          }),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateDef template;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onOpen;

  const _TemplateCard({
    required this.template,
    required this.isFavorite,
    required this.onFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final defaults = {for (final f in template.fields) f.key: f.initial};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: GestureDetector(
        onTap: onOpen,
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox.fromSize(
                      size: kCardSize,
                      child: template.builder(defaults),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.55, 1],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withAlpha(190),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : _dark,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          template.category,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6, top: 2),
                        child: Text(
                          template.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 56,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Use this template',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: _dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
