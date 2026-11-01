import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return _buildCards(context, crossAxisCount: 1);
    }
    if (width < 1280) {
      return _buildCards(context, crossAxisCount: 2);
    }
    return _buildTable(context);
  }

  Widget _buildTable(BuildContext context) {
    final sortIndex = _sortColumnIndex();
    Widget buildCellWrapper(Widget child) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 14, color: Colors.black),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            child: child,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: DataTable(
            sortColumnIndex: sortIndex,
            sortAscending: sortAscending,
            columnSpacing: 30,
            horizontalMargin: 24,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 52,
            headingRowHeight: 44,
            onSelectAll: onToggleSelect != null
                ? (bool? value) {
                    if (value == true) {
                      for (final item in items) {
                        if (!selected.contains(idOf(item))) {
                          onToggleSelect!(idOf(item));
                        }
                      }
                    } else {
                      for (final item in items) {
                        if (selected.contains(idOf(item))) {
                          onToggleSelect!(idOf(item));
                        }
                      }
                    }
                  }
                : null,
            columns: [
              ...columns.map(
                (col) => DataColumn(
                  label: buildCellWrapper(
                    Text(
                      col.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  numeric: col.numeric,
                  onSort: col.sortField != null && onSort != null
                      ? (_, _) => onSort!(col.sortField!)
                      : null,
                ),
              ),
              if (actions != null &&
                  items.isNotEmpty &&
                  actions!(items.first).isNotEmpty)
                DataColumn(
                  label: buildCellWrapper(
                    const Text(
                      'Действия',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
            rows: items
                .map(
                  (item) => DataRow(
                    selected: selected.contains(idOf(item)),
                    onSelectChanged: onToggleSelect != null
                        ? (_) => onToggleSelect!(idOf(item))
                        : null,
                    cells: [
                      ...columns.map(
                        (col) => DataCell(buildCellWrapper(col.build(item))),
                      ),
                      if (actions != null)
                        DataCell(
                          buildCellWrapper(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions!(item),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  int? _sortColumnIndex() {
    if (sortField == null) return null;
    final offset = onToggleSelect != null ? 1 : 0;
    final index = columns.indexWhere((c) => c.sortField == sortField);
    return index != -1 ? index + offset : null;
  }

  Widget _buildCards(BuildContext context, {required int crossAxisCount}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 12;
        final double totalWidth = constraints.maxWidth;
        final double cardWidth = crossAxisCount == 1
            ? totalWidth - 32
            : (totalWidth - 32 - spacing) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((item) {
              final isSelected = selected.contains(idOf(item));
              return SizedBox(
                width: cardWidth,
                child: _buildCard(context, item, isSelected),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, T item, bool isSelected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggleSelect != null
            ? () => onToggleSelect!(idOf(item))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onToggleSelect != null)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect!(idOf(item)),
                    ),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      child: columns.first.build(item),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              ...columns
                  .skip(1)
                  .map(
                    (col) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${col.label}:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              child: col.build(item),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (actions != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
