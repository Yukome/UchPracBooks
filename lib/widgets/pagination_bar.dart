import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final bool hasPrevious;
  final bool hasNext;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPageChanged,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: hasPrevious
                  ? () => onPageChanged(currentPage - 1)
                  : null,
            ),
            Text(
              '$currentPage / $totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: hasNext ? () => onPageChanged(currentPage + 1) : null,
            ),
          ],
        ),
      );
    }

    if (width < 1280) {
      return Container(
        width: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(left: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: hasPrevious
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              tooltip: 'Вверх',
            ),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: 3,
              child: Text(
                'Стр. $currentPage из $totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: hasNext ? () => onPageChanged(currentPage + 1) : null,
              tooltip: 'Вниз',
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '$totalItems',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Показывать по: '),
              DropdownButton<int>(
                value: pageSize,
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: (val) {
                  if (val != null) onSizeChanged(val);
                },
              ),
              const SizedBox(width: 16),
              Text('Всего записей: $totalItems'),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: hasPrevious ? () => onPageChanged(1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: hasPrevious
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              Text(
                'Страница $currentPage из $totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: hasNext
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: hasNext ? () => onPageChanged(totalPages) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
