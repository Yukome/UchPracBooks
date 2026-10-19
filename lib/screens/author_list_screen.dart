import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/author_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../models/author.dart';
import '../models/author_query.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      final q = uri.queryParameters;

      if (q.isNotEmpty) {
        final currentQuery = context.read<AuthorListNotifier>().query;
        context.read<AuthorListNotifier>().applyQuery(
          currentQuery.copyWith(
            search: q['search'] ?? '',
            yearFrom: int.tryParse(q['yearFrom'] ?? ''),
            yearTo: int.tryParse(q['yearTo'] ?? ''),
            sortField: q['sortField'] ?? 'fullName',
            sortAscending: q['sortAscending'] != 'false',
            page: int.tryParse(q['page'] ?? '1') ?? 1,
            size: int.tryParse(q['size'] ?? '10') ?? 10,
            includeDeleted: q['includeDeleted'] == 'true',
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _updateQuery(AuthorQuery newQuery) {
    context.read<AuthorListNotifier>().applyQuery(newQuery);
    final uri = GoRouterState.of(context).uri;
    final newParams = <String, String>{};

    if (newQuery.search.isNotEmpty) newParams['search'] = newQuery.search;
    if (newQuery.yearFrom != null) newParams['yearFrom'] = newQuery.yearFrom.toString();
    if (newQuery.yearTo != null) newParams['yearTo'] = newQuery.yearTo.toString();
    if (newQuery.sortField != 'fullName') newParams['sortField'] = newQuery.sortField;
    if (!newQuery.sortAscending) newParams['sortAscending'] = 'false';
    if (newQuery.page != 1) newParams['page'] = newQuery.page.toString();
    if (newQuery.size != 10) newParams['size'] = newQuery.size.toString();
    if (newQuery.includeDeleted) newParams['includeDeleted'] = 'true';

    context.go(uri.replace(queryParameters: newParams).toString());
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _updateQuery(context.read<AuthorListNotifier>().query.copyWith(search: value, page: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторы'),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<AuthorListNotifier>().clearSelection();
              _updateQuery(const AuthorQuery());
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Сбросить', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Поиск по ФИО или стране',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 16),
                if (notifier.hasSelection)
                  FilledButton.icon(
                    onPressed: () async {
                      await context.read<AuthorListNotifier>().deleteSelected();
                      if (!mounted) return;
                      _updateQuery(context.read<AuthorListNotifier>().query);
                    },
                    icon: const Icon(Icons.delete),
                    label: Text('Удалить (${notifier.selected.length})'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: notifier.query.yearFrom?.toString(),
                    decoration: const InputDecoration(labelText: 'Год от', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (val) => _updateQuery(notifier.query.copyWith(yearFrom: int.tryParse(val), page: 1)),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: notifier.query.yearTo?.toString(),
                    decoration: const InputDecoration(labelText: 'Год до', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (val) => _updateQuery(notifier.query.copyWith(yearTo: int.tryParse(val), page: 1)),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: notifier.query.includeDeleted,
                      onChanged: (val) => _updateQuery(notifier.query.copyWith(includeDeleted: val, page: 1)),
                    ),
                    const Text('Показать удалённые'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: switch (notifier.status) {
              AuthorLoadStatus.idle || AuthorLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              AuthorLoadStatus.error =>
                const Center(child: Text('Ошибка загрузки')),
              AuthorLoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Авторов не найдено')),
              AuthorLoadStatus.success =>
                Column(
                  children: [
                    Expanded(
                      child: EntityTable<Author>(
                        items: notifier.result.items,
                        idOf: (a) => a.id,
                        selected: notifier.selected,
                        onToggleSelect: (id) => context.read<AuthorListNotifier>().toggleSelection(id),
                        sortField: notifier.query.sortField,
                        sortAscending: notifier.query.sortAscending,
                        onSort: (field) => _updateQuery(
                          notifier.query.copyWith(
                            sortField: field,
                            sortAscending: field == notifier.query.sortField
                                ? !notifier.query.sortAscending
                                : true,
                          ),
                        ),
                        columns: [
                          TableColumnSpec(label: 'ФИО', sortField: 'fullName', build: (a) => Text(
                            a.fullName,
                            style: TextStyle(
                              decoration: a.isDeleted ? TextDecoration.lineThrough : null,
                              color: a.isDeleted ? Colors.grey : null,
                            )
                          )),
                          TableColumnSpec(label: 'Год рождения', sortField: 'birthYear', numeric: true, build: (a) => Text('${a.birthYear ?? "-"}')),
                          TableColumnSpec(label: 'Страна', sortField: 'country', build: (a) => Text(a.country)),
                        ],
                        actions: (a) => [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: a.isDeleted ? null : () {}
                          ),
                          if (a.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              tooltip: 'Восстановить',
                              onPressed: () async {
                                await context.read<AuthorListNotifier>().restoreOne(a.id);
                                if (!mounted) return;
                                _updateQuery(context.read<AuthorListNotifier>().query);
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Удалить',
                              onPressed: () async {
                                await context.read<AuthorListNotifier>().deleteOne(a.id);
                                if (!mounted) return;
                                _updateQuery(context.read<AuthorListNotifier>().query);
                              },
                            ),
                        ],
                      ),
                    ),
                    PaginationBar(
                      currentPage: notifier.query.page,
                      totalPages: notifier.result.totalPages,
                      totalItems: notifier.result.total,
                      pageSize: notifier.query.size,
                      hasPrevious: notifier.result.hasPrevious,
                      hasNext: notifier.result.hasNext,
                      onPageChanged: (p) => _updateQuery(notifier.query.copyWith(page: p)),
                      onSizeChanged: (s) => _updateQuery(notifier.query.copyWith(size: s, page: 1)),
                    ),
                  ],
                ),
            },
          ),
        ],
      ),
    );
  }
}