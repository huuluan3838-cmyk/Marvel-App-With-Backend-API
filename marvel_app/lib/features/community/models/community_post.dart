class CommunityPost {
  final int id;
  final String authorName;
  final String authorAvatar;
  final String timeAgo;
  final String title;
  final String contentSnippet;
  final String imagePath;
  final String category;
  int likes;
  int comments;
  bool isLiked;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.timeAgo,
    required this.title,
    required this.contentSnippet,
    required this.imagePath,
    required this.category,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    String timeAgoStr = 'Vừa xong';
    if (json['ngayDang'] != null) {
      DateTime postDate = DateTime.parse(json['ngayDang']);
      Duration diff = DateTime.now().difference(postDate);
      if (diff.inDays > 0) {
        timeAgoStr = '${diff.inDays} ngày trước';
      } else if (diff.inHours > 0) {
        timeAgoStr = '${diff.inHours} giờ trước';
      } else if (diff.inMinutes > 0) {
        timeAgoStr = '${diff.inMinutes} phút trước';
      }
    }

    return CommunityPost(
      id: json['maBaiViet'] ?? 0,
      authorName: 'Người dùng',
      authorAvatar: 'U',
      timeAgo: timeAgoStr,
      title: json['tieuDe'] ?? '',
      contentSnippet: json['noiDung'] ?? '',
      imagePath: json['hinhAnh'] ?? '',
      category: json['theLoai'] ?? 'Khác',
      likes: json['luotThich'] ?? 0,
      comments: 0,
    );
  }
}
