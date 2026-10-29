import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/publisher_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../state/auth_notifier.dart';
import '../models/app_user.dart';
import '../main.dart';

class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> with RouteAware {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      final q = uri.queryParameters;

      if (q.isNotEmpty) {
        final currentQuery = context.read<PublisherListNotifier>().query;
        context.read<PublisherListNotifier>().applyQuery(
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
    context.read<PublisherListNotifier>().load();
  }

  void _updateQuery(PublisherQuery newQuery) {
    context.read<PublisherListNotifier>().applyQuery(newQuery);
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
      _updateQuery(context.read<PublisherListNotifier>().query.copyWith(search: value, page: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PublisherListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final isLibrarian = auth.has(Role.librarian);
    final isAdmin = auth.has(Role.admin);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'На главную',
          onPressed: () => context.go('/'),
        ),
        title: const Text('Издательства'),
        actions: [
          if (isLibrarian)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.go('/publishers/new'),
            ),
          TextButton.icon(
            onPressed: () {
              context.read<PublisherListNotifier>().clearSelection();
              _updateQuery(const PublisherQuery());
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
                      labelText: 'Поиск по названию или городу',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 16),
                if (notifier.hasSelection && isLibrarian)
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await context.read<PublisherListNotifier>().deleteSelected();
                        if (!mounted) return;
                        context.read<PublisherListNotifier>().load();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: Text('Удалить (${notifier.selected.length})'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  )
              ],
            ),
          ),
          if (isAdmin)
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
              PublisherLoadStatus.idle || PublisherLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              PublisherLoadStatus.error => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(notifier.error ?? 'Ошибка загрузки', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.read<PublisherListNotifier>().load(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              PublisherLoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Издательств не найдено')),
              PublisherLoadStatus.success =>
                Column(
                  children: [
                    Expanded(
                      child: EntityTable<Publisher>(
                        items: notifier.result.items,
                        idOf: (p) => p.id,
                        selected: isLibrarian ? notifier.selected : const {},
                        onToggleSelect: isLibrarian ? (id) => context.read<PublisherListNotifier>().toggleSelection(id) : null,
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
                          TableColumnSpec(label: 'Название', sortField: 'name', build: (p) => Text(
                            p.name,
                            style: TextStyle(
                              decoration: p.isDeleted ? TextDecoration.lineThrough : null,
                              color: p.isDeleted ? Colors.grey : null,
                            )
                          )),
                          TableColumnSpec(label: 'Город', sortField: 'city', build: (p) => Text(p.city)),
                          TableColumnSpec(label: 'Год основания', sortField: 'foundedYear', numeric: true, build: (p) => Text('${p.foundedYear ?? "-"}')),
                        ],
                        actions: (p) {
                          if (!isLibrarian) return [];
                          return [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: p.isDeleted ? null : () => context.go('/publishers/${p.id}/edit'),
                            ),
                            if (p.isDeleted) 
                              if (isAdmin) 
                                IconButton(
                                  icon: const Icon(Icons.restore, color: Colors.green),
                                  onPressed: () async {
                                    try {
                                      await context.read<PublisherListNotifier>().restoreOne(p.id);
                                      if (!mounted) return;
                                      context.read<PublisherListNotifier>().load();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                                ),
                            if (!p.isDeleted) 
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                tooltip: 'Действия',
                                onSelected: (value) async {
                                  try {
                                    if (value == 'soft') {
                                      await context.read<PublisherListNotifier>().deleteOne(p.id);
                                    } else if (value == 'hard' && isAdmin) {
                                      await context.read<PublisherListNotifier>().hardDeleteOne(p.id);
                                    }
                                    if (!mounted) return;
                                    context.read<PublisherListNotifier>().load();
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'soft', child: Text('В корзину (логически)')),
                                  if (isAdmin)
                                    const PopupMenuItem(value: 'hard', child: Text('Удалить навсегда', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                          ];
                        },
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