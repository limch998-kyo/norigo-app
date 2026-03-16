import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/landmark.dart';

class LandmarkInputList extends StatefulWidget {
  final List<Landmark?> landmarks;
  final Future<List<Landmark>> Function(String query) onSearch;
  final void Function(int index, Landmark landmark) onSelect;
  final void Function(int index) onRemove;
  final VoidCallback onAdd;
  final int minCount;
  final int maxCount;
  final String locale;

  const LandmarkInputList({
    super.key,
    required this.landmarks,
    required this.onSearch,
    required this.onSelect,
    required this.onRemove,
    required this.onAdd,
    this.minCount = 2,
    this.maxCount = 10,
    this.locale = 'en',
  });

  @override
  State<LandmarkInputList> createState() => _LandmarkInputListState();
}

class _LandmarkInputListState extends State<LandmarkInputList> {
  int? _activeIndex;
  List<Landmark> _suggestions = [];
  Timer? _debounce;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};

  TextEditingController _getController(int index) {
    return _controllers.putIfAbsent(index, () => TextEditingController());
  }

  FocusNode _getFocusNode(int index) {
    return _focusNodes.putIfAbsent(index, () => FocusNode());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in _controllers.values) c.dispose();
    for (final f in _focusNodes.values) f.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _suggestions = []; _activeIndex = null; });
      return;
    }
    setState(() => _activeIndex = index);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await widget.onSearch(value.trim());
        if (mounted && _activeIndex == index) {
          setState(() => _suggestions = results);
        }
      } catch (_) {}
    });
  }

  void _onSelect(int index, Landmark landmark) {
    widget.onSelect(index, landmark);
    _getController(index).text = landmark.name;
    setState(() { _suggestions = []; _activeIndex = null; });
    _getFocusNode(index).unfocus();
  }

  String _spotLabel(int index) {
    final n = index + 1;
    switch (widget.locale) {
      case 'ja': return 'スポット $n';
      case 'ko': return '관광지 $n';
      case 'zh': return '景点 $n';
      default: return 'Spot $n';
    }
  }

  String get _addLabel {
    switch (widget.locale) {
      case 'ja': return 'スポットを追加';
      case 'ko': return '관광지 추가';
      case 'zh': return '添加景点';
      default: return 'Add spot';
    }
  }

  String get _placeholder {
    switch (widget.locale) {
      case 'ja': return '観光地名を入力...';
      case 'ko': return '관광지 이름 입력...';
      case 'zh': return '输入景点名...';
      default: return 'Enter landmark name...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.landmarks.asMap().entries.map((entry) {
          final i = entry.key;
          final landmark = entry.value;
          final controller = _getController(i);

          if (landmark != null && controller.text != landmark.name) {
            controller.text = landmark.name;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        _spotLabel(i),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.mutedForeground),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: _getFocusNode(i),
                        onChanged: (v) => _onChanged(v, i),
                        decoration: InputDecoration(
                          hintText: _placeholder,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: landmark != null ? AppTheme.primary : AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (widget.landmarks.length > widget.minCount)
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: AppTheme.mutedForeground),
                        onPressed: () {
                          _controllers.remove(i)?.dispose();
                          widget.onRemove(i);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      )
                    else
                      const SizedBox(width: 32),
                  ],
                ),
                if (_activeIndex == i && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 72, top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, si) {
                        final l = _suggestions[si];
                        return InkWell(
                          onTap: () => _onSelect(i, l),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                const Text('📍 ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      if (l.nameEn != null)
                                        Text(l.nameEn!, style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }),

        if (widget.landmarks.length < widget.maxCount)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(_addLabel, style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
      ],
    );
  }
}
