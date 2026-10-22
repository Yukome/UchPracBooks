import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/genre_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../main.dart';

class GenreListScreen extends StatefulWidget {
  const GenreListScreen({super.key});

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> with RouteAware {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      final q = uri.queryParameters;

      if (q.isNotEmpty) {
        final currentQuery = context.read<GenreListNotifier>().query;
        context.read<GenreListNotifier>().applyQuery(
          currentQuery.copyWith(
            search: q['search'] ?? '',
            sortField: q['sortField'] ?? 'name',
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
    context.read<GenreListNotifier>().load();
  }

  void _updateQuery(GenreQuery newQuery) {
    context.read<GenreListNotifier>().applyQuery(newQuery);
    final uri = GoRouterState.of(context).uri;
    final newParams = <String, String>{};

    if (newQuery.search.isNotEmpty) newParams['search'] = newQuery.search;
    if (newQuery.sortField != 'name') newParams['sortField'] = newQuery.sortField;
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
      _updateQuery(context.read<GenreListNotifier>().query.copyWith(search: value, page: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenreListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жанры'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/genres/new'),
          ),
          TextButton.icon(
            onPressed: () {
              context.read<GenreListNotifier>().clearSelection();
              _updateQuery(const GenreQuery());
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
                      labelText: 'Поиск по названию или описанию',
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
                      await context.read<GenreListNotifier>().deleteSelected();
                      if (!mounted) return;
                      _updateQuery(context.read<GenreListNotifier>().query);
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
              GenreLoadStatus.idle || GenreLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              GenreLoadStatus.error =>
                const Center(child: Text('Ошибка загрузки')),
              GenreLoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Жанров не найдено')),
              GenreLoadStatus.success =>
                Column(
                  children: [
                    Expanded(
                      child: EntityTable<Genre>(
                        items: notifier.result.items,
                        idOf: (g) => g.id,
                        selected: notifier.selected,
                        onToggleSelect: (id) => context.read<GenreListNotifier>().toggleSelection(id),
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
                          TableColumnSpec(label: 'Название', sortField: 'name', build: (g) => Text(
                            g.name,
                            style: TextStyle(
                              decoration: g.isDeleted ? TextDecoration.lineThrough : null,
                              color: g.isDeleted ? Colors.grey : null,
                            )
                          )),
                          TableColumnSpec(label: 'Описание', build: (g) => Text(g.description)),
                        ],
                        actions: (g) => [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: g.isDeleted ? null : () => context.go('/genres/${g.id}/edit'),
                          ),
                          if (g.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              onPressed: () async {
                                await context.read<GenreListNotifier>().restoreOne(g.id);
                                if (!mounted) return;
                                _updateQuery(context.read<GenreListNotifier>().query);
                              },
                            )
                          else
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Действия',
                              onSelected: (value) async {
                                if (value == 'soft') {
                                  await context.read<GenreListNotifier>().deleteOne(g.id);
                                } else if (value == 'hard') {
                                  await context.read<GenreListNotifier>().hardDeleteOne(g.id);
                                }
                                if (!mounted) return;
                                _updateQuery(context.read<GenreListNotifier>().query);
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