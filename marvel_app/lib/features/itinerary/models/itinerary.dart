class Itinerary {
  final int id;
  final String title;
  final String destination;
  final String date;
  final String duration;
  final String imagePath;
  final bool isUpcoming;

  Itinerary({
    required this.id,
    required this.title,
    required this.destination,
    required this.date,
    required this.duration,
    required this.imagePath,
    required this.isUpcoming,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    String dateRange = '';
    String durationStr = '';

    if (json['ngayBatDau'] != null && json['ngayKetThuc'] != null) {
      DateTime start = DateTime.parse(json['ngayBatDau']);
      DateTime end = DateTime.parse(json['ngayKetThuc']);
      dateRange =
          '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';

      int days = end.difference(start).inDays + 1;
      int nights = days > 1 ? days - 1 : 0;
      durationStr = '$days Ngày $nights Đêm';
    }

    return Itinerary(
      id: json['maLichTrinh'] ?? 0,
      title: json['tieuDe'] ?? 'Hành trình mới',
      destination: json['danhSachDiaDiem'] ?? 'Nhiều địa điểm',
      date: dateRange,
      duration: durationStr,
      imagePath: 'assets/images/VinhHaLong.jpg',
      isUpcoming: json['trangThai'] == 'Upcoming',
    );
  }
}
