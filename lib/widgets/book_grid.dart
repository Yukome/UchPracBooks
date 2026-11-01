import 'package:flutter/material.dart';
import '../models/book.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;
  const BookGrid({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

    double cardWidth;
    double cardHeight;
    double maxContainerWidth;

    if (screenWidth < 768) {
      cardWidth = 260;
      cardHeight = 340;
      maxContainerWidth = cardWidth;
    } else if (screenWidth < 1280) {
      cardWidth = 280;
      cardHeight = 360;
      maxContainerWidth = (cardWidth * 3) + 32;
    } else if (screenWidth < 1600) {
      cardWidth = 300;
      cardHeight = 380;
      maxContainerWidth = (cardWidth * 4) + 48;
    } else {
      cardWidth = 300;
      cardHeight = 380;
      maxContainerWidth = (cardWidth * 4) + 48;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        screenWidth < 768 ? 16 : 24,
        screenWidth < 768 ? 16 : 24,
        screenWidth < 768 ? 16 : 24,
        screenWidth < 768 ? 16 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContainerWidth),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: books.map((book) {
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(
                              Icons.book,
                              size: screenWidth < 768 ? 64 : 48,
                              color: book.isDeleted
                                  ? Colors.grey
                                  : Colors.indigo,
                            ),
                          ),
                        ),
                        Text(
                          book.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: book.isDeleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: book.isDeleted ? Colors.grey : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Год: ${book.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'В наличии: ${book.copiesAvailable} шт.',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
