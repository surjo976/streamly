class Channel {
  final String name;
  final String logo;
  final String group;
  final String url;

  Channel({
    required this.name,
    required this.logo,
    required this.group,
    required this.url,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      name: json['name'] as String? ?? 'Unknown Channel',
      logo: json['logo'] as String? ?? '',
      group: json['group'] as String? ?? 'General',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logo': logo,
      'group': group,
      'url': url,
    };
  }
}
