class PageResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PageResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PageResult.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    if (json is! Map<String, dynamic> || json['items'] is! List) {
      throw const FormatException('Invalid paginated response');
    }

    return PageResult<T>(
      items: (json['items'] as List)
          .map((item) => parseItem(Map<String, dynamic>.from(item as Map)))
          .toList(),
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 25,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}
