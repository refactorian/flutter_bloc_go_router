import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final int id;
  final int postId;
  final String name;
  final String email;
  final String body;

  const Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      postId: json['postId'] is int
          ? json['postId'] as int
          : int.tryParse(json['postId']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'name': name,
    'email': email,
    'body': body,
  };

  @override
  List<Object?> get props => [id, postId, name, email, body];
}
