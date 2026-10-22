import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/reader_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../main.dart';

class ReaderListScreen extends StatefulWidget {
  const ReaderListScreen({super.key});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> with RouteAware {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      final q = uri.queryParameters;

      if (q.isNotEmpty) {
        final currentQuery = context.read<ReaderListNotifier>().query;
        context.read<ReaderListNotifier>().applyQuery(
          currentQuery.copyWith(
            search: q['search'] ?? '',
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<ReaderListNotifier>().load();
  }

  void _updateQuery(ReaderQuery newQuery) {
    context.read<ReaderListNotifier>().applyQuery(newQuery);
    final uri = GoRouterState.of(context).uri;
    final newParams = <String, String>{};

    if (newQuery.search.isNotEmpty) newParams['search'] = newQuery.search;
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
      _updateQuery(context.read<ReaderListNotifier>().query.copyWith(search: value, page: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReaderListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Читатели'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/readers/new'),
          ),
          TextButton.icon(
            onPressed: () {
              context.read<ReaderListNotifier>().clearSelection();
              _updateQuery(const ReaderQuery());
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
                      labelText: 'Поиск по ФИО или Email',
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
                      await context.read<ReaderListNotifier>().deleteSelected();
                      if (!mounted) return;
                      _updateQuery(context.read<ReaderListNotifier>().query);
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
            child: Row(
              children: [
                Checkbox(
                  value: notifier.query.includeDeleted,
                  onChanged: (val) => _updateQuery(notifier.query.copyWith(includeDeleted: val, page: 1)),
                ),
                const Text('Показать удалённые'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: switch (notifier.status) {
              ReaderLoadStatus.idle || ReaderLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              ReaderLoadStatus.error =>
                const Center(child: Text('Ошибка загрузки')),
              ReaderLoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Читателей не найдено')),
              ReaderLoadStatus.success =>
                Column(
                  children: [
                    Expanded(
                      child: EntityTable<Reader>(
                        items: notifier.result.items,
                        idOf: (r) => r.id,
                        selected: notifier.selected,
                        onToggleSelect: (id) => context.read<ReaderListNotifier>().toggleSelection(id),
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
                          TableColumnSpec(label: 'ФИО', sortField: 'fullName', build: (r) => Text(
                            r.fullName,
                            style: TextStyle(
                              decoration: r.isDeleted ? TextDecoration.lineThrough : null,
                              color: r.isDeleted ? Colors.grey : null,
                            )
                          )),
                          TableColumnSpec(label: 'Email', build: (r) => Text(r.email)),
                          TableColumnSpec(label: 'Билет', build: (r) => Text(r.card?.number ?? 'Нет')),
                        ],
                        actions: (r) => [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: r.isDeleted ? null : () => context.go('/readers/${r.id}/edit'),
                          ),
                          if (r.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              onPressed: () async {
                                await context.read<ReaderListNotifier>().restoreOne(r.id);
                                if (!mounted) return;
                                _updateQuery(context.read<ReaderListNotifier>().query);
                              },
                            )
                          else
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Действия',
                              onSelected: (value) async {
                                if (value == 'soft') {
                                  await context.read<ReaderListNotifier>().deleteOne(r.id);
                                } else if (value == 'hard') {
                                  await context.read<ReaderListNotifier>().hardDeleteOne(r.id);
                                }
                                if (!mounted) return;
                                _updateQuery(context.read<ReaderListNotifier>().query);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'soft',
                                  child: Text('В корзину (логически)'),
                                ),
                                const PopupMenuItem(
                                  value: 'hard',
                                  child: Text('Удалить навсегда', style: TextStyle(color: Colors.red)),
                                ),
                              ],
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