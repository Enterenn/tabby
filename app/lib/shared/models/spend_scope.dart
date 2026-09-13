enum SpendScope {
  all,
  groups,
  personal;

  String get apiValue => switch (this) {
        SpendScope.all => 'all',
        SpendScope.groups => 'groups',
        SpendScope.personal => 'personal',
      };
}
