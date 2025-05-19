import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class SentimentScreen extends StatefulWidget {
  const SentimentScreen({super.key});

  @override
  State<SentimentScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<SentimentScreen> {
  final TextEditingController _reviewController = TextEditingController();
  List<Map<String, dynamic>> reviews = [];
  DateTime? _lastRequestTime;
  Duration _minRequestInterval = const Duration(seconds: 1);
  String baseUrl = 'http://localhost:5000'; // .NET API default port; Android: 'http://10.0.2.2:5000'
  String? currentReviewId;
  bool isAnalyzing = false;
  http.Client? _currentClient;

  String currentModel = 'gemini-1.5-flash';
  String apiKey = 'AIzaSyA-7IcYzs8SGl-y5jBy-UNfT_7098rxCAw'; // Replace with your Gemini API key

  // 🧠 Call Gemini API for sentiment analysis
  Future<Map<String, dynamic>> getSentimentAnalysis(String review) async {
    _currentClient?.close();
    final client = http.Client();
    _currentClient = client;

    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent?key=$apiKey';

    final prompt = '''
    Analyze the sentiment of the following review and classify it into one of five levels: Very Negative, Negative, Neutral, Positive, or Very Positive. Provide a brief explanation for the classification.

    Review: $review

    Respond in the format:
    **Sentiment**: [Very Negative/Negative/Neutral/Positive/Very Positive]
    **Explanation**: [Your explanation]
    ''';

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['candidates'][0]['content']['parts'][0]['text'];
        return parseSentimentResponse(rawText);
      } else if (response.statusCode == 429) {
        return {
          'sentiment': 'Error',
          'explanation': 'Rate limit exceeded. Please wait and try again.'
        };
      } else {
        return {
          'sentiment': 'Error',
          'explanation': 'API error (${response.statusCode}): Unable to process.'
        };
      }
    } catch (e) {
      return {
        'sentiment': 'Error',
        'explanation': 'Request failed: $e'
      };
    } finally {
      client.close();
      _currentClient = null;
    }
  }

  // Parse sentiment analysis response
  Map<String, dynamic> parseSentimentResponse(String raw) {
    String sentiment = 'Neutral';
    String explanation = raw;

    final sentimentMatch = RegExp(r'\*\*Sentiment\*\*:\s*(Very Negative|Negative|Neutral|Positive|Very Positive)').firstMatch(raw);
    final explanationMatch = RegExp(r'\*\*Explanation\*\*:\s*(.*?)(?:\n|$)', dotAll: true).firstMatch(raw);

    if (sentimentMatch != null) {
      sentiment = sentimentMatch.group(1)!;
    }
    if (explanationMatch != null) {
      explanation = explanationMatch.group(1)!.trim();
    }

    return {
      'sentiment': sentiment,
      'explanation': cleanResponseText(explanation)
    };
  }

  // Clean response text
  String cleanResponseText(String raw) {
    String text = raw;
    text = text.replaceAll(RegExp(r'(`{1,3})(.*?)\1'), '');
    text = text.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1');
    text = text.replaceAll(RegExp(r'\*(.*?)\*'), r'\1');
    text = text.replaceAll(RegExp(r'_([^_]+)_'), r'\1');
    text = text.replaceAll(RegExp(r'~~(.*?)~~'), r'\1');
    text = text.replaceAll(RegExp(r'\[(.*?)\]\((.*?)\)'), r'\1');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.trim();
    return text;
  }

  // Submit review for analysis
  void analyzeReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty || isAnalyzing) return;

    setState(() {
      isAnalyzing = true;
    });

    final result = await getSentimentAnalysis(text);

    final reviewEntry = {
      'text': text,
      'sentiment': result['sentiment'],
      'explanation': result['explanation'],
      'time': DateTime.now().toIso8601String(),
    };

    setState(() {
      isAnalyzing = false;
      reviews.add(reviewEntry);
      _reviewController.clear();
    });

    final success = await saveReviewHistory(reviews);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save review to backend')),
      );
    }
  }

  // Save review history
  Future<bool> saveReviewHistory(List<Map<String, dynamic>> reviews) async {
    final reviewData = {
      "userId": "guest",
      "name": reviews.last['text'].substring(0, reviews.last['text'].length > 30 ? 30 : reviews.last['text'].length),
      "reviews": reviews.map((r) => {
        "text": r['text'],
        "sentiment": r['sentiment'],
        "explanation": r['explanation'],
        "time": r['time'],
      }).toList(),
      "createdAt": DateTime.now().toIso8601String(), // Thêm trường createdAt để khớp với model Review
    };

    debugPrint('Sending review data to backend: ${jsonEncode(reviewData)}'); // Log dữ liệu gửi đi

    try {
      if (currentReviewId == null) {
        final response = await http.post(
          Uri.parse('$baseUrl/api/reviews/save'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(reviewData),
        );

        debugPrint('POST Response: ${response.statusCode} - ${response.body}'); // Log phản hồi

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          currentReviewId = data['_id'];
          return true;
        } else {
          debugPrint('Failed to save review: ${response.statusCode} - ${response.body}');
          return false;
        }
      } else {
        final response = await http.put(
          Uri.parse('$baseUrl/api/reviews/update/$currentReviewId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(reviewData),
        );

        debugPrint('PUT Response: ${response.statusCode} - ${response.body}'); // Log phản hồi

        return response.statusCode == 200;
      }
    } catch (e) {
      debugPrint('Error saving review: $e');
      return false;
    }
  }

  // Create new review session
  void createNewReviewSession() {
    setState(() {
      reviews.clear();
      currentReviewId = null;
    });
  }

  // Load latest review
  Future<void> loadLatestReview() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/reviews/latest/guest'));

      debugPrint('GET Latest Response: ${response.statusCode} - ${response.body}'); // Log phản hồi

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> loadedReviews = data['reviews'] ?? [];

        setState(() {
          reviews.clear();
          reviews.addAll(
            loadedReviews.map((r) => {
              'text': r['text'],
              'sentiment': r['sentiment'],
              'explanation': r['explanation'],
              'time': r['time'],
            }),
          );
        });
        debugPrint("Loaded latest review successfully");
      } else {
        debugPrint("No review found: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error loading review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load latest review')),
      );
    }
  }

  // Fetch all review summaries
  Future<List<ReviewSummary>> fetchReviews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/reviews/all/guest'));

      debugPrint('GET All Response: ${response.statusCode} - ${response.body}'); // Log phản hồi

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ReviewSummary.fromJson(json)).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch review history')),
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch review history')),
      );
      return [];
    }
  }

  // Load review by ID
  Future<void> loadReviewById(String reviewId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/reviews/$reviewId'));

      debugPrint('GET By ID Response: ${response.statusCode} - ${response.body}'); // Log phản hồi

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> loadedReviews = data['reviews'] ?? [];

        setState(() {
          reviews.clear();
          reviews.addAll(
            loadedReviews.map((r) => {
              'text': r['text'],
              'sentiment': r['sentiment'],
              'explanation': r['explanation'],
              'time': r['time'],
            }),
          );
        });
        debugPrint("Loaded review $reviewId");
      } else {
        debugPrint("Review not found: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load review')),
        );
      }
    } catch (e) {
      debugPrint('Error loading review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load review')),
      );
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/reviews/delete/$reviewId'));

      debugPrint('DELETE Response: ${response.statusCode} - ${response.body}'); // Log phản hồi

      if (response.statusCode == 200) {
        debugPrint('Review deleted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted')),
        );
      } else {
        debugPrint('Deletion failed: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deletion failed')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting review')),
      );
    }
  }

  // Confirm deletion
  void confirmDeleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteReview(reviewId);
    }
  }

  // Group reviews by time
  Map<String, List<ReviewSummary>> groupReviewsByTime(List<ReviewSummary> reviews) {
    final Map<String, List<ReviewSummary>> grouped = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'This Month': [],
      'Older': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    for (var review in reviews) {
      final createdAt = DateTime.tryParse(review.timestamp) ?? now;

      if (createdAt.isAfter(today)) {
        grouped['Today']!.add(review);
      } else if (createdAt.isAfter(yesterday)) {
        grouped['Yesterday']!.add(review);
      } else if (createdAt.isAfter(weekStart)) {
        grouped['This Week']!.add(review);
      } else if (createdAt.isAfter(monthStart)) {
        grouped['This Month']!.add(review);
      } else {
        grouped['Older']!.add(review);
      }
    }

    return grouped;
  }

  @override
  void initState() {
    super.initState();
    // For Android emulator, use: baseUrl = 'http://10.0.2.2:5000';
    loadLatestReview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: Drawer(
        child: FutureBuilder<List<ReviewSummary>>(
          future: fetchReviews(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text('Error loading reviews or no reviews found'));
            }

            final reviews = snapshot.data ?? [];
            final groupedReviews = groupReviewsByTime(reviews);

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text('Review History', style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
                ...groupedReviews.entries.expand((entry) {
                  final groupName = entry.key;
                  final groupReviews = entry.value;

                  if (groupReviews.isEmpty) return [];

                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    ...groupReviews.map((r) => ListTile(
                      title: Text('🗓 ${r.name}'),
                      subtitle: Text('⭐ ${r.sentiment}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => confirmDeleteReview(r.id),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        loadReviewById(r.id);
                      },
                    )),
                  ];
                }),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Review Sentiment Analysis'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New review session',
              onPressed: isAnalyzing ? null : createNewReviewSession,
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Review Input Form
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Your Review',
                        style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reviewController,
                        maxLines: 4,
                        enabled: !isAnalyzing,
                        decoration: InputDecoration(
                          hintText: 'Enter your review here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: GoogleFonts.notoSans(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: isAnalyzing ? null : analyzeReview,
                          icon: Icon(isAnalyzing ? Icons.hourglass_empty : Icons.send),
                          label: Text(isAnalyzing ? 'Analyzing...' : 'Đánh giá'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Review Results
              Text(
                'Recent Reviews',
                style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                  child: Text(
                    'No reviews yet. Submit a review to see results.',
                    style: GoogleFonts.notoSans(fontSize: 14, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return ReviewCard(
                      reviewText: review['text'],
                      sentiment: review['sentiment'],
                      explanation: review['explanation'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String reviewText;
  final String sentiment;
  final String explanation;

  const ReviewCard({
    super.key,
    required this.reviewText,
    required this.sentiment,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    Color sentimentColor;
    switch (sentiment) {
      case 'Very Positive':
        sentimentColor = Colors.green.shade700;
        break;
      case 'Positive':
        sentimentColor = Colors.green.shade400;
        break;
      case 'Neutral':
        sentimentColor = Colors.grey.shade500;
        break;
      case 'Negative':
        sentimentColor = Colors.red.shade400;
        break;
      case 'Very Negative':
        sentimentColor = Colors.red.shade700;
        break;
      default:
        sentimentColor = Colors.grey.shade500;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review:',
              style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              reviewText,
              style: GoogleFonts.notoSans(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Sentiment: ',
                  style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  sentiment,
                  style: GoogleFonts.notoSans(fontSize: 14, color: sentimentColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Explanation:',
              style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              explanation,
              style: GoogleFonts.notoSans(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewSummary {
  final String id;
  final String name;
  final String sentiment;
  final int count;
  final String timestamp;

  ReviewSummary({
    required this.id,
    required this.name,
    required this.sentiment,
    required this.count,
    required this.timestamp,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled',
      sentiment: json['reviews']?.isNotEmpty == true ? json['reviews'][0]['sentiment'] : 'Unknown',
      count: json['reviews']?.length ?? 0,
      timestamp: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}