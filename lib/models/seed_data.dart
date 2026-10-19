import 'book.dart';

final List<Book> seedBooks = [
  const Book(id: 1, title: 'Война и мир', isbn: '978-5-17-118366-4', year: 1869, pages: 1300, publisherId: 1, authorIds: [1], genreIds: [1, 3], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 2, title: 'Анна Каренина', isbn: '978-5-17-090620-1', year: 1877, pages: 864, publisherId: 1, authorIds: [1], genreIds: [1, 3], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 3, title: 'Преступление и наказание', isbn: '978-5-389-06003-6', year: 1866, pages: 672, publisherId: 3, authorIds: [2], genreIds: [1, 3], copiesTotal: 5, copiesAvailable: 5),
  const Book(id: 4, title: 'Идиот', isbn: '978-5-389-07773-7', year: 1869, pages: 640, publisherId: 3, authorIds: [2], genreIds: [1, 3], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 5, title: 'Братья Карамазовы', isbn: '978-5-04-089115-8', year: 1880, pages: 1024, publisherId: 2, authorIds: [2], genreIds: [1, 3], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 6, title: 'Мастер и Маргарита', isbn: '978-5-17-084362-9', year: 1967, pages: 480, publisherId: 1, authorIds: [3], genreIds: [1, 2, 3], copiesTotal: 6, copiesAvailable: 6),
  const Book(id: 7, title: 'Собачье сердце', isbn: '978-5-17-088237-6', year: 1925, pages: 192, publisherId: 1, authorIds: [3], genreIds: [1, 2], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 8, title: 'Пикник на обочине', isbn: '978-5-17-096909-1', year: 1972, pages: 288, publisherId: 1, authorIds: [4, 5], genreIds: [2], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 9, title: 'Трудно быть богом', isbn: '978-5-17-095832-3', year: 1964, pages: 224, publisherId: 1, authorIds: [4, 5], genreIds: [2], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 10, title: 'Понедельник начинается в субботу', isbn: '978-5-17-097584-9', year: 1965, pages: 320, publisherId: 1, authorIds: [4, 5], genreIds: [2], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 11, title: '1984', isbn: '978-5-17-080115-5', year: 1949, pages: 320, publisherId: 1, authorIds: [6], genreIds: [4, 2], copiesTotal: 5, copiesAvailable: 5),
  const Book(id: 12, title: 'Скотный двор', isbn: '978-5-17-097584-1', year: 1945, pages: 144, publisherId: 1, authorIds: [6], genreIds: [4], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 13, title: '451 градус по Фаренгейту', isbn: '978-5-04-004643-9', year: 1953, pages: 272, publisherId: 2, authorIds: [7], genreIds: [4, 2], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 14, title: 'Марсианские хроники', isbn: '978-5-04-089116-5', year: 1950, pages: 352, publisherId: 2, authorIds: [7], genreIds: [2], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 15, title: 'Вино из одуванчиков', isbn: '978-5-04-093471-6', year: 1957, pages: 320, publisherId: 2, authorIds: [7], genreIds: [1], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 16, title: 'Три товарища', isbn: '978-5-17-088179-9', year: 1936, pages: 480, publisherId: 1, authorIds: [8], genreIds: [1], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 17, title: 'На Западном фронте без перемен', isbn: '978-5-17-088180-5', year: 1929, pages: 288, publisherId: 1, authorIds: [8], genreIds: [1, 3], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 18, title: 'Триумфальная арка', isbn: '978-5-17-088181-2', year: 1945, pages: 480, publisherId: 1, authorIds: [8], genreIds: [1], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 19, title: 'Чистая архитектура', isbn: '978-5-4461-0772-8', year: 2017, pages: 352, publisherId: 4, authorIds: [], genreIds: [6], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 20, title: 'Совершенный код', isbn: '978-5-4461-0906-7', year: 2004, pages: 896, publisherId: 4, authorIds: [], genreIds: [6], copiesTotal: 1, copiesAvailable: 1),
];