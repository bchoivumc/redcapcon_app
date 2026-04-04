import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> availableDates;
  final List<String> availableTypes;
  final List<String> availableAudiences;
  final Set<String> selectedDates;
  final Set<String> selectedTypes;
  final Set<String> selectedAudiences;
  final Function(Set<String>, Set<String>, Set<String>) onApply;

  const FilterBottomSheet({
    super.key,
    required this.availableDates,
    required this.availableTypes,
    required this.availableAudiences,
    required this.selectedDates,
    required this.selectedTypes,
    required this.selectedAudiences,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<String> _selectedDates;
  late Set<String> _selectedTypes;
  late Set<String> _selectedAudiences;

  @override
  void initState() {
    super.initState();
    _selectedDates = Set.from(widget.selectedDates);
    _selectedTypes = Set.from(widget.selectedTypes);
    _selectedAudiences = Set.from(widget.selectedAudiences);
  }

  String _formatDate(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('EEEE, MMM d').format(date);
    } catch (e) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Sessions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDates.clear();
                        _selectedTypes.clear();
                        _selectedAudiences.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Date',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableDates.map((date) {
                      final isSelected = _selectedDates.contains(date);
                      return FilterChip(
                        label: Text(_formatDate(date)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDates.add(date);
                            } else {
                              _selectedDates.remove(date);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Session Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableTypes.map((type) {
                      final isSelected = _selectedTypes.contains(type);
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTypes.add(type);
                            } else {
                              _selectedTypes.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Audience',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableAudiences.map((audience) {
                      final isSelected = _selectedAudiences.contains(audience);
                      return FilterChip(
                        label: Text(audience),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAudiences.add(audience);
                            } else {
                              _selectedAudiences.remove(audience);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_selectedDates, _selectedTypes, _selectedAudiences);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
