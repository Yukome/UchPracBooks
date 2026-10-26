import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/book_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../repositories/publisher_repository.dart';
import '../repositories/book_repository.dart';
import '../models/filter_data.dart';
import '../main.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> with RouteAware {
  Timer? _debounce;
  List<Publisher> _publishers = [];
  List<int> _availableGenreIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final pubRepo = context.read<PublisherRepository>();
      final pubsResult = await pubRepo.find(const PublisherQuery(size: 1000));
      if (mounted) setState(() => _publishers = pubsResult.items);
      setState(() => _availableGenreIds = genres.keys.toList());
      final uri = GoRouterState.of(context).uri;
      final q = uri.queryParameters;
      
      if (q.isNotEmpty) {
        final currentQuery = context.read<BookListNotifier>().query;
        context.read<BookListNotifier>().applyQuery(
          currentQuery.copyWith(
            search: q['search'] ?? '',
            genreId: int.tryParse(q['genreId'] ?? ''),
            publisherId: int.tryParse(q['publisherId'] ?? ''),
            yearFrom: int.tryParse(q['yearFrom'] ?? ''),
            yearTo: int.tryParse(q['yearTo'] ?? ''),
            sortField: q['sortField'] ?? 'title',
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
    context.read<BookListNotifier>().load();
  }

  void _updateQuery(BookQuery newQuery) {
    context.read<BookListNotifier>().applyQuery(newQuery);
    final uri = GoRouterState.of(context).uri;
    final newParams = <String, String>{};
    
    if (newQuery.search.isNotEmpty) newParams['search'] = newQuery.search;
    if (newQuery.genreId != null) newParams['genreId'] = newQuery.genreId.toString();
    if (newQuery.publisherId != null) newParams['publisherId'] = newQuery.publisherId.toString();
    if (newQuery.yearFrom != null) newParams['yearFrom'] = newQuery.yearFrom.toString();
    if (newQuery.yearTo != null) newParams['yearTo'] = newQuery.yearTo.toString();
    if (newQuery.sortField != 'title') newParams['sortField'] = newQuery.sortField;
    if (!newQuery.sortAscending) newParams['sortAscending'] = 'false';
    if (newQuery.page != 1) newParams['page'] = newQuery.page.toString();
    if (newQuery.size != 10) newParams['size'] = newQuery.size.toString();
    if (newQuery.includeDeleted) newParams['includeDeleted'] = 'true';
    
    context.go(uri.replace(queryParameters: newParams).toString());
  }

  Future<void> _onPublisherFilterChanged(int? publisherId) async {
    final newQuery = context.read<BookListNotifier>().query.copyWith(
      publisherId: publisherId,
      genreId: null, 
      page: 1,
    );

    if (publisherId == null) {
      setState(() => _availableGenreIds = genres.keys.toList());
    } else {
      final repo = context.read<BookRepository>();
      final result = await repo.find(BookQuery(publisherId: publisherId, size: 1000));
      
      final genreIds = <int>{};
      for (final book in result.items) {
        genreIds.addAll(book.genreIds);
      }

      if (mounted) {
        setState(() {
          _availableGenreIds = genreIds.isEmpty ? genres.keys.toList() : genreIds.toList();
        });
      }
    }

    _updateQuery(newQuery);
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _updateQuery(context.read<BookListNotifier>().query.copyWith(search: value, page: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог книг'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить книгу',
            onPressed: () => context.go('/books/new'),
          ),
          TextButton.icon(
            onPressed: () {
              context.read<BookListNotifier>().clearSelection();
              setState(() => _availableGenreIds = genres.keys.toList());
              _updateQuery(const BookQuery());
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Сбросить', style: TextStyle(color: Color.fromARGB(255, 18, 15, 20))),
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
                      labelText: 'Поиск по названию или ISBN',
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
                      try {
                        await context.read<BookListNotifier>().deleteSelected();
                        if (!mounted) return;
                        _updateQuery(context.read<BookListNotifier>().query);
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: DropdownButtonFormField<int?>(
                    value: notifier.query.genreId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Жанр', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все', overflow: TextOverflow.ellipsis)),
                      ...genres.entries
                          .where((e) => _availableGenreIds.contains(e.key))
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) => _updateQuery(notifier.query.copyWith(genreId: val, page: 1)),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: DropdownButtonFormField<int?>(
                    value: notifier.query.publisherId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder(), isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Все', overflow: TextOverflow.ellipsis)),
                      ..._publishers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (val) => _onPublisherFilterChanged(val),
                  ),
                ),
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
              LoadStatus.idle || LoadStatus.loading => 
                const Center(child: CircularProgressIndicator()),
              LoadStatus.error => 
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(notifier.error ?? 'Ошибка'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => context.read<BookListNotifier>().load(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              LoadStatus.success when notifier.result.items.isEmpty => 
                const Center(child: Text('Книг не найдено')),
              LoadStatus.success => 
                Column(
                  children: [
                    Expanded(
                      child: EntityTable<Book>(
                        items: notifier.result.items,
                        idOf: (b) => b.id,
                        selected: notifier.selected,
                        onToggleSelect: (id) => context.read<BookListNotifier>().toggleSelection(id),
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
                          TableColumnSpec(label: 'Название', sortField: 'title', build: (b) => Text(
                            b.title, 
                            style: TextStyle(
                              decoration: b.isDeleted ? TextDecoration.lineThrough : null,
                              color: b.isDeleted ? Colors.grey : null,
                            )
                          )),
                          TableColumnSpec(label: 'Год', sortField: 'year', numeric: true, build: (b) => Text('${b.year}')),
                          TableColumnSpec(label: 'Страниц', sortField: 'pages', numeric: true, build: (b) => Text('${b.pages}')),
                          TableColumnSpec(label: 'Экземпляры', build: (b) => Text('${b.copiesAvailable} / ${b.copiesTotal}')),
                        ],
                        actions: (b) => [
                          IconButton(
                            icon: const Icon(Icons.edit), 
                            onPressed: b.isDeleted 
                                ? null 
                                : () => context.go('/books/${b.id}/edit'),
                          ),
                          if (b.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              tooltip: 'Восстановить',
                              onPressed: () async {
                                try {
                                  await context.read<BookListNotifier>().restoreOne(b.id);
                                  if (!mounted) return;
                                  _updateQuery(context.read<BookListNotifier>().query);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                  );
                                }
                              },
                            )
                          else
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Действия',
                              onSelected: (value) async {
                                try {
                                  if (value == 'soft') {
                                    await context.read<BookListNotifier>().deleteOne(b.id);
                                  } else if (value == 'hard') {
                                    await context.read<BookListNotifier>().hardDeleteOne(b.id);
                                  }
                                  if (!mounted) return;
                                  _updateQuery(context.read<BookListNotifier>().query);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                  );
                                }
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