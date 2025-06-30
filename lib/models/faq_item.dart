import 'dart:convert';

class RelatedLink {
  final String label;
  final String url;

  RelatedLink({required this.label, required this.url});

  factory RelatedLink.fromJson(Map<String, dynamic> json) {
    return RelatedLink(
      label: json['label'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'url': url,
    };
  }
}

class FAQItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final List<RelatedLink> relatedLinks;
  
  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.relatedLinks = const [],
  });
  
  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String,
      relatedLinks: (json['relatedLinks'] as List<dynamic>?)
          ?.map((link) => RelatedLink.fromJson(link as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'relatedLinks': relatedLinks.map((link) => link.toJson()).toList(),
    };
  }
  
  @override
  String toString() {
    return 'FAQItem(id: $id, question: $question, category: $category)';
  }
}