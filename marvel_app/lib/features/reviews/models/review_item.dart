class ReviewItem {
  final String title;
  final String location;
  final String date;
  final String content;
  final double rating;

  const ReviewItem({
    required this.title,
    required this.location,
    required this.date,
    required this.content,
    required this.rating,
  });

  ReviewItem copyWith({String? content}) {
    return ReviewItem(
      title: title,
      location: location,
      date: date,
      content: content ?? this.content,
      rating: rating,
    );
  }
}
