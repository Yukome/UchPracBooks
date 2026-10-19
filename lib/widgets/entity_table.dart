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
    if (MediaQuery.sizeOf(context).width < 600) {
      return _buildCards(context);
    }
    return _buildTable(context);
  }

  Widget _buildTable(BuildContext context) {
    final sortIndex = _sortColumnIndex();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
          child: DataTable(
            sortColumnIndex: sortIndex,
            sortAscending: sortAscending,
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
              ...columns.map((col) => DataColumn(
                label: Text(col.label),
                numeric: col.numeric,
                onSort: col.sortField != null && onSort != null
                    ? (_, __) => onSort!(col.sortField!)
                    : null,
              )),
              if (actions != null) const DataColumn(label: Text('Действия')),
            ],
            rows: items.map((item) => DataRow(
              selected: selected.contains(idOf(item)),
              onSelectChanged: onToggleSelect != null
                  ? (_) => onToggleSelect!(idOf(item))
                  : null,
              cells: [
                ...columns.map((col) => DataCell(col.build(item))),
                if (actions != null) DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!(item),
                )),
              ],
            )).toList(),
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

  Widget _buildCards(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onToggleSelect != null)
                      Checkbox(
                        value: selected.contains(idOf(item)),
                        onChanged: (_) => onToggleSelect!(idOf(item)),
                      ),
                    Expanded(
                      child: DefaultTextStyle(
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                        child: columns.first.build(item),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...columns.skip(1).map((col) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 120, child: Text('${col.label}:', style: const TextStyle(color: Colors.grey))),
                      Expanded(child: col.build(item)),
                    ],
                  ),
                )),
                if (actions != null) ...[
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!(item)),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}