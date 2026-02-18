import 'package:flutter_test/flutter_test.dart';
import 'package:indulge/view/common/util/pagination_controller.dart';

void main() {
  group('PaginationController', () {
    test('loadInitial loads up to pageSize and sets currentPage to 1', () {
      final controller = PaginationController<int>(pageSize: 3);
      final allItems = List<int>.generate(5, (i) => i + 1); // [1,2,3,4,5]

      final loaded = controller.loadInitial(allItems);

      expect(loaded.length, 3);
      expect(controller.displayedCount, 3);
      expect(controller.currentPage, 1);
      expect(loaded, [1, 2, 3]);
    });

    test('loadMore loads subsequent pages and stops at end', () {
      final controller = PaginationController<int>(pageSize: 3);
      final allItems = List<int>.generate(5, (i) => i + 1); // [1,2,3,4,5]

      controller.loadInitial(allItems);
      final more = controller.loadMore(allItems);

      expect(more.length, 2);
      expect(more, [4, 5]);
      expect(controller.displayedCount, 5);
      expect(controller.currentPage, 2);

      // No more items after that
      final none = controller.loadMore(allItems);
      expect(none, isEmpty);
      expect(controller.displayedCount, 5);
      expect(controller.currentPage, 2);
    });

    test('canLoadMore respects isLoadingMore and item counts', () {
      final controller = PaginationController<int>(pageSize: 2);
      final allItems = [1, 2, 3];

      // Initially can load more because nothing displayed yet
      expect(controller.canLoadMore(allItems), isTrue);

      // Simulate loading in progress
      controller.isLoadingMore = true;
      expect(controller.canLoadMore(allItems), isFalse);
      controller.isLoadingMore = false;

      // Load initial page then remaining
      controller.loadInitial(allItems);
      expect(controller.displayedCount, 2);
      expect(controller.canLoadMore(allItems), isTrue);

      controller.loadMore(allItems);
      expect(controller.displayedCount, 3);
      expect(controller.canLoadMore(allItems), isFalse);
    });

    test('reset clears state', () {
      final controller = PaginationController<int>(pageSize: 2);
      final allItems = [1, 2, 3, 4];

      controller.loadInitial(allItems);
      controller.loadMore(allItems);

      expect(controller.displayedCount, greaterThan(0));
      expect(controller.currentPage, greaterThan(0));

      controller.reset();

      expect(controller.displayedCount, 0);
      expect(controller.currentPage, 0);
      expect(controller.isLoadingMore, isFalse);
    });

    test('loadInitial with empty list does nothing', () {
      final controller = PaginationController<int>(pageSize: 3);
      final loaded = controller.loadInitial(<int>[]);

      expect(loaded, isEmpty);
      expect(controller.displayedCount, 0);
      expect(controller.currentPage, 0);
    });

    test('loadMore without prior loadInitial behaves like initial load', () {
      final controller = PaginationController<int>(pageSize: 2);
      final allItems = [10, 20, 30];

      final newItems = controller.loadMore(allItems);

      // It should load the first page
      expect(newItems, [10, 20]);
      expect(controller.displayedCount, 2);
      expect(controller.currentPage, 1);
    });

    test('loadMore is no-op when already at end', () {
      final controller = PaginationController<int>(pageSize: 5);
      final allItems = [1, 2, 3];

      controller.loadInitial(allItems);
      expect(controller.displayedCount, 3);
      expect(controller.currentPage, 1);

      final extra = controller.loadMore(allItems);
      expect(extra, isEmpty);
      expect(controller.displayedCount, 3);
      expect(controller.currentPage, 1);
    });
  });
}
