import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/station.dart';

class StationInputList extends StatefulWidget {
  final List<Station?> stations;
  final Future<List<Station>> Function(String query) onSearch;
  final void Function(int index, Station station) onSelect;
  final void Function(int index) onRemove;
  final VoidCallback onAdd;
  final int minCount;
  final int maxCount;
  final String locale;

  const StationInputList({
    super.key,
    required this.stations,
    required this.onSearch,
    required this.onSelect,
    required this.onRemove,
    required this.onAdd,
    this.minCount = 2,
    this.maxCount = 10,
    this.locale = 'en',
  });

  @override
  State<StationInputList> createState() => _StationInputListState();
}

class _StationInputListState extends State<StationInputList> {
  int? _activeIndex;
  List<Station> _suggestions = [];
  Timer? _debounce;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  List<Station?>? _prevStations;

  TextEditingController _getController(int index) {
    return _controllers.putIfAbsent(index, () => TextEditingController());
  }

  FocusNode _getFocusNode(int index) {
    final node = _focusNodes.putIfAbsent(index, () => FocusNode());
    // Auto-select first result on blur (matching web handleBlur)
    node.addListener(() {
      if (!node.hasFocus && _activeIndex == index && _suggestions.isNotEmpty) {
        // If field lost focus and no selection was made, auto-select first
        final station = widget.stations[index];
        if (station == null && _suggestions.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && widget.stations.length > index && widget.stations[index] == null) {
              _onSelect(index, _suggestions.first);
            }
          });
        }
      }
    });
    return node;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _activeIndex = null;
      });
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

  void _onSelect(int index, Station station) {
    widget.onSelect(index, station);
    _getController(index).text = station.localizedName(widget.locale);
    setState(() {
      _suggestions = [];
      _activeIndex = null;
    });
    _getFocusNode(index).unfocus();
  }

  String _personLabel(int index) {
    final n = index + 1;
    switch (widget.locale) {
      case 'ja':
        return '出発駅 $n';
      case 'ko':
        return '출발역 $n';
      case 'fr':
        return 'Gare $n';
      default:
        return 'Person $n';
    }
  }

  String get _addLabel {
    switch (widget.locale) {
      case 'ja':
        return '人を追加';
      case 'ko':
        return '인원 추가';
      case 'zh':
        return '添加人员';
      case 'fr':
        return 'Ajouter une personne';
      default:
        return 'Add person';
    }
  }

  String get _placeholder {
    switch (widget.locale) {
      case 'ja':
        return '駅名を入力...';
      case 'ko':
        return '역 이름 입력...';
      case 'zh':
        return '输入车站名...';
      case 'fr':
        return 'Nom de la gare...';
      default:
        return 'Enter station name...';
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prevStations = List.from(widget.stations);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.stations.asMap().entries.map((entry) {
          final i = entry.key;
          final station = entry.value;
          final controller = _getController(i);

          // Sync controller text only when stations actually changed (region switch)
          final prevStation = (_prevStations != null && i < _prevStations!.length) ? _prevStations![i] : null;
          final stationChanged = (prevStation?.id != station?.id) || (prevStation?.name != station?.name);
          if (stationChanged) {
            if (station != null) {
              controller.text = station.localizedName(widget.locale);
            } else {
              controller.text = '';
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Label
                    SizedBox(
                      width: 72,
                      child: Text(
                        _personLabel(i),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                    // Input
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
                            borderSide: BorderSide(
                              color: station != null ? AppTheme.primary : AppTheme.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    // Remove button
                    if (widget.stations.length > widget.minCount)
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
                // Suggestions dropdown
                if (_activeIndex == i && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 72, top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, si) {
                        final s = _suggestions[si];
                        return InkWell(
                          onTap: () => _onSelect(i, s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                const Text('🚉 ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.localizedName(widget.locale),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      if (s.lines.isNotEmpty)
                                        Text(
                                          s.lines.take(3).join(', ') +
                                              (s.lines.length > 3 ? ' +${s.lines.length - 3}' : ''),
                                          style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                                        ),
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

        // Add person button
        if (widget.stations.length < widget.maxCount)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(_addLabel, style: const TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
      ],
    );
  }
}
