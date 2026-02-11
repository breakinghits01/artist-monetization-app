import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist_model.freezed.dart';
part 'playlist_model.g.dart';

@freezed
class PlaylistModel with _$PlaylistModel {
  const factory PlaylistModel({
    required String id,
    required String userId,
    required String name,
    String? description,
    String? coverImage,
    @Default(true) bool isPublic,
    @Default([]) List<String> songs,
    @Default(0) int songCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PlaylistModel;

  factory PlaylistModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistModelFromJson(json);
}
