class BannerModel {
  final String id;
  final String imageUrl;
  final String? mobileImageUrl;
  final String actionType;
  final Map<String, dynamic> actionPayload;
  final int priority;
  final int displayOrder;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.mobileImageUrl,
    required this.actionType,
    required this.actionPayload,
    this.priority = 0,
    this.displayOrder = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      mobileImageUrl: json['mobile_image_url']?.toString(),
      actionType: json['action_type']?.toString() ?? 'none',
      actionPayload: json['action_payload'] is Map<String, dynamic>
          ? json['action_payload'] as Map<String, dynamic>
          : (json['action_payload'] is Map
              ? Map<String, dynamic>.from(json['action_payload'] as Map)
              : {}),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'mobile_image_url': mobileImageUrl,
      'action_type': actionType,
      'action_payload': actionPayload,
      'priority': priority,
      'display_order': displayOrder,
    };
  }
}
