enum UserType { cliente, estabelecimento, entregador, admin, unknown }

extension UserTypeX on UserType {
  static UserType fromString(String? s) => switch (s) {
        'cliente' => UserType.cliente,
        'estabelecimento' => UserType.estabelecimento,
        'entregador' => UserType.entregador,
        'admin' => UserType.admin,
        _ => UserType.unknown,
      };

  /// Deriva o tipo da rota retornada pelo banco — para uso em UI (ícones, labels).
  static UserType fromRoute(String route) {
    if (route.startsWith('/admin')) return UserType.admin;
    if (route.startsWith('/dashboard_estabelecimento')) return UserType.estabelecimento;
    if (route.startsWith('/dashboard_entregador')) return UserType.entregador;
    if (route.startsWith('/home')) return UserType.cliente;
    return UserType.unknown;
  }
}
