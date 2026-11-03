enum Role {
  reader(1, 'Клиент'),
  librarian(2, 'Инструктор'),
  admin(3, 'Управляющий');

  final int level;
  final String title;
  const Role(this.level, this.title);

  static Role fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'admin' => Role.admin,
      'librarian' => Role.librarian,
      _ => Role.reader,
    };
  }
}
