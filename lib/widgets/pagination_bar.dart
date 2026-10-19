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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Всего записей: $totalItems'),
          Row(
            children: [
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
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: hasPrevious ? () => onPageChanged(1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: hasPrevious ? () => onPageChanged(currentPage - 1) : null,
              ),
              Text('Стр. $currentPage из $totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: hasNext ? () => onPageChanged(currentPage + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: hasNext ? () => onPageChanged(totalPages) : null,
              ),
            ],
          )
        ],
      ),
    );
  }
}