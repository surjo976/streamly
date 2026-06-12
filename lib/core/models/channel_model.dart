class Channel {
  final String id;
  final String name;
  final String logo;
  final String group;
  final String url;

  Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.group,
    required this.url,
  });

  factory Channel.fromJson(Map<String, dynamic> json, String id) {
    return Channel(
      id: id,
      name: json['name'] as String? ?? 'Unknown Channel',
      logo: json['logo'] as String? ?? '',
      group: json['group'] as String? ?? 'General',
      url: (json['url'] as String? ?? '').replaceAll('&amp;', '&'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'group': group,
      'url': url,
    };
  }
}
