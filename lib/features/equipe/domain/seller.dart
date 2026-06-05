class Seller {
  const Seller({this.id, required this.name, this.role, this.isActive = true});

  final String? id;
  final String name;
  final String? role;
  final bool isActive;

  factory Seller.fromSupabase(Map<String, dynamic> row) {
    return Seller(
      id: row['id']?.toString(),
      name: row['name']?.toString() ?? '',
      role: row['role']?.toString(),
      isActive: row['is_active'] != false,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name': name.trim(),
      'role': role?.trim().isEmpty ?? true ? null : role?.trim(),
      'is_active': isActive,
    };
  }
}
