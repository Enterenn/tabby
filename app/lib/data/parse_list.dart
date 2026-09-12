List<T> parseJsonList<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  return (data as List)
      .map((item) => fromJson(item as Map<String, dynamic>))
      .toList();
}
