class AdminPost {
  final int id;
  final String author;
  final String title;
  final String category;
  final String status;
  final String date;

  AdminPost({
    required this.id,
    required this.author,
    required this.title,
    required this.category,
    required this.status,
    required this.date,
  });

  factory AdminPost.fromJson(Map<String, dynamic> json) {
    final rawDate = json['ngayDang']?.toString() ?? '';
    return AdminPost(
      id: json['maBaiViet'] is int
          ? json['maBaiViet']
          : int.tryParse(json['maBaiViet']?.toString() ?? '0') ?? 0,
      author: 'User ',
      title: json['tieuDe']?.toString() ?? '',
      category: json['theLoai']?.toString() ?? '',
      status: json['trangThai']?.toString() ?? 'Pending',
      date: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
    );
  }
}
