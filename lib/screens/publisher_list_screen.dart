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

class _PublisherListScreenState extends State<PublisherListScreen>
    with RouteAware {
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
    if (newQuery.sortField != 'name')
      {newParams['sortField'] = newQuery.sortField;}
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
      _updateQuery(
        context.read<PublisherListNotifier>().query.copyWith(
          search: value,
          page: 1,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PublisherListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final isLibrarian = auth.has(Role.librarian);
    final isAdmin = auth.has(Role.admin);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSidePagination = screenWidth >= 600 && screenWidth < 1280;

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
            label: const Text(
              'Сбросить',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 500;
                        final searchField = TextField(
                          decoration: const InputDecoration(
                            labelText: 'Поиск по названию или городу',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: _onSearchChanged,
                        );
                        final deleteButton =
                            (notifier.hasSelection && isLibrarian)
                            ? FilledButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final publisherNotifier = context
                                      .read<PublisherListNotifier>();

                                  try {
                                    await publisherNotifier.deleteSelected();
                                    if (!mounted) return;
                                    publisherNotifier.load();
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete),
                                label: Text(
                                  'Удалить (${notifier.selected.length})',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              )
                            : null;

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              if (deleteButton != null) ...[
                                const SizedBox(height: 12),
                                deleteButton,
                              ],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: searchField),
                            if (deleteButton != null) ...[
                              const SizedBox(width: 12),
                              deleteButton,
                            ],
                          ],
                        );
                      },
                    ),
                  ),

                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: notifier.query.includeDeleted,
                              onChanged: (val) => _updateQuery(
                                notifier.query.copyWith(
                                  includeDeleted: val,
                                  page: 1,
                                ),
                              ),
                            ),
                            const Text('Показать удалённые'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
                    Text(
                      notifier.error ?? 'Ошибка загрузки',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () =>
                          context.read<PublisherListNotifier>().load(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              PublisherLoadStatus.success when notifier.result.items.isEmpty =>
                const Center(child: Text('Издательств не найдено')),
              PublisherLoadStatus.success => Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: EntityTable<Publisher>(
                            items: notifier.result.items,
                            idOf: (p) => p.id,
                            selected: isLibrarian
                                ? notifier.selected
                                : const {},
                            onToggleSelect: isLibrarian
                                ? (id) => context
                                      .read<PublisherListNotifier>()
                                      .toggleSelection(id)
                                : null,
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
                              TableColumnSpec(
                                label: 'Название',
                                sortField: 'name',
                                build: (p) => Text(
                                  p.name,
                                  style: TextStyle(
                                    decoration: p.isDeleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: p.isDeleted ? Colors.grey : null,
                                  ),
                                ),
                              ),
                              TableColumnSpec(
                                label: 'Город',
                                sortField: 'city',
                                build: (p) => Text(p.city),
                              ),
                              TableColumnSpec(
                                label: 'Год основания',
                                sortField: 'foundedYear',
                                numeric: true,
                                build: (p) => Text('${p.foundedYear ?? "-"}'),
                              ),
                            ],
                            actions: (p) {
                              if (!isLibrarian) return [];
                              return [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: p.isDeleted
                                      ? null
                                      : () => context.go(
                                          '/publishers/${p.id}/edit',
                                        ),
                                ),
                                if (p.isDeleted)
                                  if (isAdmin)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.restore,
                                        color: Colors.green,
                                      ),
                                      tooltip: 'Восстановить',
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final publisherNotifier = context
                                            .read<PublisherListNotifier>();

                                        try {
                                          await publisherNotifier.restoreOne(
                                            p.id,
                                          );
                                          if (!mounted) return;
                                          publisherNotifier.load();
                                        } catch (e) {
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                if (!p.isDeleted)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    tooltip: 'Действия',
                                    onSelected: (value) async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final publisherNotifier = context
                                          .read<PublisherListNotifier>();

                                      try {
                                        if (value == 'soft') {
                                          await publisherNotifier.deleteOne(
                                            p.id,
                                          );
                                        } else if (value == 'hard' && isAdmin) {
                                          await publisherNotifier.hardDeleteOne(
                                            p.id,
                                          );
                                        }
                                        if (!mounted) return;
                                        publisherNotifier.load();
                                      } catch (e) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'soft',
                                        child: Text('В корзину (логически)'),
                                      ),
                                      if (isAdmin)
                                        const PopupMenuItem(
                                          value: 'hard',
                                          child: Text(
                                            'Удалить навсегда',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                              ];
                            },
                          ),
                        ),
                        if (!isSidePagination)
                          PaginationBar(
                            currentPage: notifier.query.page,
                            totalPages: notifier.result.totalPages,
                            totalItems: notifier.result.total,
                            pageSize: notifier.query.size,
                            hasPrevious: notifier.result.hasPrevious,
                            hasNext: notifier.result.hasNext,
                            onPageChanged: (p) =>
                                _updateQuery(notifier.query.copyWith(page: p)),
                            onSizeChanged: (s) => _updateQuery(
                              notifier.query.copyWith(size: s, page: 1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSidePagination)
                    SizedBox(
                      width: 80,
                      child: PaginationBar(
                        currentPage: notifier.query.page,
                        totalPages: notifier.result.totalPages,
                        totalItems: notifier.result.total,
                        pageSize: notifier.query.size,
                        hasPrevious: notifier.result.hasPrevious,
                        hasNext: notifier.result.hasNext,
                        onPageChanged: (p) =>
                            _updateQuery(notifier.query.copyWith(page: p)),
                        onSizeChanged: (s) => _updateQuery(
                          notifier.query.copyWith(size: s, page: 1),
                        ),
                      ),
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
