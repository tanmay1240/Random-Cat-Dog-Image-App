import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

void main() => runApp(const PetPicsApp());

class PetPicsApp extends StatelessWidget {
  const PetPicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Cat / Dog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const HomePage(),
    );
  }
}

enum PetType { cat, dog }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  PetType _pet = PetType.cat;
  String? _imgUrl;
  bool _loading = false;

  // Confetti controller
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  Future<void> _fetchImage() async {
    setState(() => _loading = true);
    final url = _pet == PetType.dog
        ? Uri.parse('https://dog.ceo/api/breeds/image/random')
        : Uri.parse('https://api.thecatapi.com/v1/images/search');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final imageUrl = _pet == PetType.dog
            ? body['message'] as String
            : body[0]['url'] as String;
        setState(() => _imgUrl = imageUrl);
        _confetti.forward(from: 0); // fire confetti
      } else {
        throw Exception('Server answered ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Oops: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _pet == PetType.dog
        ? [Colors.orange.shade200, Colors.orange.shade600]
        : [Colors.purple.shade200, Colors.purple.shade600];

    return Scaffold(
      body: Stack(
        // ① use Stack
        children: [
          // --- background gradient ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // --- main UI wrapped in SafeArea ---
          SafeArea(
            child: Column(
              children: [
                // Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  child: SegmentedButton<PetType>(
                    segments: const [
                      ButtonSegment(value: PetType.cat, label: Text('Cats 🐱')),
                      ButtonSegment(value: PetType.dog, label: Text('Dogs 🐶')),
                    ],
                    selected: <PetType>{_pet},
                    onSelectionChanged: (s) {
                      setState(() => _pet = s.first);
                      _fetchImage();
                    },
                  ),
                ),
                // Image display
                Expanded(
                  child: Center(
                    child: _imgUrl == null
                        ? const CircularProgressIndicator()
                        : CachedNetworkImage(
                                imageUrl: _imgUrl!,
                                placeholder: (c, _) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (c, _, __) =>
                                    const Icon(Icons.error, size: 64),
                              )
                              .animate()
                              .fade(duration: 600.ms) // smooth fade‑in
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                duration: 600.ms,
                              ),
                  ),
                ),
                // Fetch button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child:
                      ElevatedButton.icon(
                            onPressed: _loading ? null : _fetchImage,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Another one!'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(fontSize: 18),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat()) // tiny bounce
                          .shake(delay: 1.seconds, duration: 4.seconds),
                ),
              ],
            ),
          ),

          // --- confetti overlay ---
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Lottie.asset(
                'assets/confetti.json',
                controller: _confetti,
                width: 700, // optional: control size
                height: 700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
