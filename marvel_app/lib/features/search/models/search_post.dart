import 'package:flutter/material.dart';

class SearchPost {
  final String title;
  final String location;
  final String author;
  final double rating;
  final int views;
  final String type;
  final Color color;

  const SearchPost({
    required this.title,
    required this.location,
    required this.author,
    this.rating = 4.5,
    this.views = 1200,
    required this.type,
    required this.color,
  });
}
