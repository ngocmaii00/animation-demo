import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const LoveAlarmMotionLabApp());
}

const Color _bg = Color(0xFF11151F);
const Color _panel = Color(0xFF1C2030);
const Color _panelSoft = Color(0xFF262B3D);
const Color _pink = Color(0xFFFF4F91);
const Color _rose = Color(0xFFFF8EAE);
const Color _mint = Color(0xFF49E7C3);
const Color _amber = Color(0xFFFFC857);
const Color _blue = Color(0xFF72A8FF);

class LoveAlarmMotionLabApp extends StatelessWidget {
  const LoveAlarmMotionLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Love Alarm Motion Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _pink,
          brightness: Brightness.dark,
          primary: _pink,
          secondary: _mint,
          surface: _panel,
        ),
        fontFamily: 'Roboto',
      ),
      home: const PresentationScreen(),
    );
  }
}

class AnimationTopic {
  const AnimationTopic({
    required this.title,
    required this.kicker,
    required this.description,
    required this.widgetsUsed,
    required this.realWorldUsage,
    required this.presenterLine,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String kicker;
  final String description;
  final List<String> widgetsUsed;
  final List<String> realWorldUsage;
  final String presenterLine;
  final IconData icon;
  final Color accent;
}

class MotionInspectorItem {
  const MotionInspectorItem({
    required this.id,
    required this.label,
    required this.category,
    required this.purpose,
    required this.code,
    required this.errorHint,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String label;
  final String category;
  final String purpose;
  final String code;
  final String errorHint;
  final IconData icon;
  final Color accent;
}

String _inspectorId(String category, String label) {
  return '${category.toLowerCase()}-$label'.replaceAll(' ', '-');
}

bool _inspectorEnabled(
  Map<String, bool> enabledById,
  String category,
  String label,
) {
  return enabledById[_inspectorId(category, label)] ?? true;
}

List<String> _disabledLabels(
  Map<String, bool> enabledById,
  String category,
  List<String> labels,
) {
  return labels
      .where((label) => !_inspectorEnabled(enabledById, category, label))
      .toList();
}

class LiveCodePatch {
  const LiveCodePatch({
    required this.item,
    required this.code,
    this.text,
    this.durationMs,
    this.slideYBegin,
    this.scaleX,
    this.scaleY,
    this.width,
    this.height,
    this.radius,
    this.padding,
    this.opacityBegin,
    this.opacityEnd,
    this.color,
    this.scaleBegin,
    this.scaleEnd,
    this.icon,
    this.error,
  });

  final MotionInspectorItem item;
  final String code;
  final String? text;
  final int? durationMs;
  final double? slideYBegin;
  final double? scaleX;
  final double? scaleY;
  final double? width;
  final double? height;
  final double? radius;
  final double? padding;
  final double? opacityBegin;
  final double? opacityEnd;
  final Color? color;
  final double? scaleBegin;
  final double? scaleEnd;
  final IconData? icon;
  final String? error;

  bool get hasError => error != null;
}

IconData _iconFromCode(String code, IconData fallback) {
  final iconMatch = RegExp(r'Icons\.([a-zA-Z0-9_]+)').firstMatch(code);
  final name = iconMatch?.group(1);
  return switch (name) {
    'favorite' => Icons.favorite,
    'favorite_border' => Icons.favorite_border,
    'search' => Icons.search,
    'notifications_active' => Icons.notifications_active,
    'person' => Icons.person,
    'person_2' => Icons.person_2,
    'check_circle' => Icons.check_circle,
    'rocket_launch' => Icons.rocket_launch,
    'auto_awesome' => Icons.auto_awesome,
    'bolt' => Icons.bolt,
    'open_in_full' => Icons.open_in_full,
    'zoom_out_map' => Icons.zoom_out_map,
    'radar' => Icons.radar,
    'swap_calls' => Icons.swap_calls,
    'play_circle' => Icons.play_circle,
    'brush' => Icons.brush,
    _ => fallback,
  };
}

LiveCodePatch _parseLiveCode(MotionInspectorItem item, String code) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) {
    return LiveCodePatch(
      item: item,
      code: code,
      error: 'Code editor is empty. Add a widget snippet before rebuilding.',
    );
  }

  final expectedError = _validateExpectedSnippet(item, code);
  if (expectedError != null) {
    return LiveCodePatch(item: item, code: code, error: expectedError);
  }

  final textMatch = RegExp(r'''Text\(["']([^"']+)["']''').firstMatch(code);
  final hasTextCall = code.contains('Text(');
  if (hasTextCall && textMatch == null) {
    return LiveCodePatch(
      item: item,
      code: code,
      error: 'Text(...) is incomplete. Example: Text(\'Signal Detected\')',
    );
  }

  final durationMs = _parseDurationMs(code);
  final scaleTernary = RegExp(
    r'scale:\s*active\s*\?\s*(-?\.?\d+(?:\.\d+)?)\s*:\s*(-?\.?\d+(?:\.\d+)?)',
  ).firstMatch(code);
  final scaleNumber = RegExp(r'scale:\s*(-?\.?\d+(?:\.\d+)?)').firstMatch(code);
  final opacityTernary = RegExp(
    r'opacity:\s*\w+\s*\?\s*(-?\.?\d+(?:\.\d+)?)\s*:\s*(-?\.?\d+(?:\.\d+)?)',
  ).firstMatch(code);
  final opacityNumber = RegExp(
    r'opacity:\s*(-?\.?\d+(?:\.\d+)?)',
  ).firstMatch(code);
  final slideMatch = RegExp(
    r'slideY\(begin:\s*(-?\.?\d+(?:\.\d+)?)',
  ).firstMatch(code);
  final offsetMatch = RegExp(
    r'Offset\((-?\.?\d+(?:\.\d+)?),\s*(-?\.?\d+(?:\.\d+)?)\)',
  ).firstMatch(code);

  final scaleEnd = scaleTernary == null
      ? (scaleNumber == null ? null : double.tryParse(scaleNumber.group(1)!))
      : double.tryParse(scaleTernary.group(1)!);
  final scaleBegin = scaleTernary == null
      ? (scaleEnd == null ? null : 1.0)
      : double.tryParse(scaleTernary.group(2)!);
  final opacityEnd = opacityTernary == null
      ? (opacityNumber == null
            ? null
            : double.tryParse(opacityNumber.group(1)!))
      : double.tryParse(opacityTernary.group(1)!);
  final opacityBegin = opacityTernary == null
      ? (opacityEnd == null ? null : 1.0)
      : double.tryParse(opacityTernary.group(2)!);

  if ((item.label == 'AnimatedScale' || item.label == 'ScaleTransition') &&
      (scaleEnd == null || scaleBegin == null)) {
    return LiveCodePatch(
      item: item,
      code: code,
      error:
          '${item.label} code must include scale, for example: scale: active ? 2 : 0.',
    );
  }
  if ((scaleEnd ?? 0) < 0 || (scaleBegin ?? 0) < 0) {
    return LiveCodePatch(
      item: item,
      code: code,
      error: 'Scale values cannot be negative.',
    );
  }
  if ((opacityEnd != null && (opacityEnd < 0 || opacityEnd > 1)) ||
      (opacityBegin != null && (opacityBegin < 0 || opacityBegin > 1))) {
    return LiveCodePatch(
      item: item,
      code: code,
      error: 'Opacity must be between 0 and 1.',
    );
  }

  return LiveCodePatch(
    item: item,
    code: code,
    text: textMatch?.group(1) ?? _usageTextFromCode(item, code),
    durationMs: durationMs,
    slideYBegin: slideMatch == null
        ? null
        : double.tryParse(slideMatch.group(1)!),
    scaleX: offsetMatch == null ? null : double.tryParse(offsetMatch.group(1)!),
    scaleY: offsetMatch == null ? null : double.tryParse(offsetMatch.group(2)!),
    width: _parseDoubleProperty(code, 'width'),
    height: _parseDoubleProperty(code, 'height'),
    radius: _parseRadius(code),
    padding: _parsePadding(code),
    opacityBegin: opacityBegin,
    opacityEnd: opacityEnd,
    color: _parseColor(code),
    scaleBegin: scaleBegin,
    scaleEnd: scaleEnd,
    icon: _iconFromCode(code, item.icon),
  );
}

String? _validateExpectedSnippet(MotionInspectorItem item, String code) {
  if (item.category == 'Usage') return null;

  final expected = switch (item.label) {
    'AnimatedContainer' => 'AnimatedContainer(',
    'AnimatedOpacity' => 'AnimatedOpacity(',
    'AnimatedPadding' => 'AnimatedPadding(',
    'AnimatedScale' => 'AnimatedScale(',
    'AnimatedSwitcher' => 'AnimatedSwitcher(',
    'AnimationController' => 'AnimationController(',
    'Tween' => 'Tween',
    'AnimatedBuilder' => 'AnimatedBuilder(',
    'Transform.rotate' => 'Transform.rotate(',
    'SlideTransition' => 'SlideTransition(',
    'FadeTransition' => 'FadeTransition(',
    'ScaleTransition' => 'ScaleTransition(',
    'Hero' => 'Hero(',
    'Navigator' => 'Navigator',
    'MaterialPageRoute' => 'MaterialPageRoute',
    'PageRoute' => 'PageRoute',
    'CustomPainter' => 'CustomPainter',
    'Canvas' => 'Canvas',
    'Paint' => 'Paint',
    'AnimatedPositioned' => 'AnimatedPositioned(',
    'lottie' => 'Lottie',
    'rive' => 'RiveAnimation',
    'flutter_animate' => '.animate()',
    'Staggered Animation' => 'Interval(',
    'SpringSimulation' => 'SpringSimulation(',
    'ShaderMask' => 'ShaderMask(',
    _ => null,
  };

  if (expected != null && !code.contains(expected)) {
    return '${item.label} live preview expects `$expected` in the code. Put it back or select another box.';
  }
  return null;
}

int? _parseDurationMs(String code) {
  final shorthand = RegExp(r'duration:\s*(\d+)\.ms').firstMatch(code);
  if (shorthand != null) return int.tryParse(shorthand.group(1)!);

  final milliseconds = RegExp(
    r'duration:\s*const\s+Duration\(milliseconds:\s*(\d+)\)',
  ).firstMatch(code);
  if (milliseconds != null) return int.tryParse(milliseconds.group(1)!);

  final seconds = RegExp(
    r'duration:\s*const\s+Duration\(seconds:\s*(\d+)\)',
  ).firstMatch(code);
  if (seconds != null) return (int.tryParse(seconds.group(1)!) ?? 0) * 1000;

  return null;
}

double? _parseDoubleProperty(String code, String property) {
  final match = RegExp(
    '$property:\\s*(-?\\.?\\d+(?:\\.\\d+)?)',
  ).firstMatch(code);
  return match == null ? null : double.tryParse(match.group(1)!);
}

double? _parseRadius(String code) {
  final match = RegExp(
    r'BorderRadius\.circular\((-?\.?\d+(?:\.\d+)?)\)',
  ).firstMatch(code);
  return match == null ? null : double.tryParse(match.group(1)!);
}

double? _parsePadding(String code) {
  final match = RegExp(
    r'EdgeInsets\.all\((-?\.?\d+(?:\.\d+)?)\)',
  ).firstMatch(code);
  return match == null ? null : double.tryParse(match.group(1)!);
}

Color? _parseColor(String code) {
  final hex = RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)').firstMatch(code);
  if (hex != null) return Color(int.parse(hex.group(1)!, radix: 16));

  final colorMatch = RegExp(r'Colors\.([a-zA-Z0-9_]+)').firstMatch(code);
  return switch (colorMatch?.group(1)) {
    'pink' => Colors.pink,
    'pinkAccent' => Colors.pinkAccent,
    'white' => Colors.white,
    'black' => Colors.black,
    'amber' => Colors.amber,
    'blue' => Colors.blue,
    'green' => Colors.green,
    'teal' => Colors.teal,
    'red' => Colors.red,
    'purple' => Colors.purple,
    _ => null,
  };
}

String? _usageTextFromCode(MotionInspectorItem item, String code) {
  if (item.category != 'Usage') return null;
  final usage = RegExp(r'//\s*Usage:\s*(.+)').firstMatch(code);
  if (usage != null) return usage.group(1)?.trim();
  final firstComment = RegExp(r'//\s*(.+)').firstMatch(code);
  return firstComment?.group(1)?.trim() ?? item.label;
}

LiveCodePatch? _activeLiveCodePatch(
  AnimationTopic topic,
  Map<String, String> codeById,
) {
  LiveCodePatch? patch;
  for (final item in _buildInspectorItems(topic)) {
    final code = codeById[item.id];
    if (code != null && code != item.code) {
      patch = _parseLiveCode(item, code);
    }
  }
  return patch;
}

const List<AnimationTopic> topics = [
  AnimationTopic(
    title: 'Love Alarm Motion Lab',
    kicker: 'Interactive presentation app',
    description:
        'A Flutter presentation built like a live demo. Each scene shows an animation first, then explains the Flutter idea behind it.',
    widgetsUsed: ['AnimatedBuilder', 'CustomPainter', 'FadeTransition'],
    realWorldUsage: ['App intro', 'Product demo', 'Class presentation'],
    presenterLine:
        'Thay vì dùng slide tĩnh, app này biến từng nội dung về Flutter Animation thành một trải nghiệm chạy trực tiếp.',
    icon: Icons.favorite,
    accent: _pink,
  ),
  AnimationTopic(
    title: 'What is Animation?',
    kicker: 'Changing UI values over time',
    description:
        'Animation changes size, color, opacity, position, rotation or shape smoothly across frames so users can understand what changed.',
    widgetsUsed: ['AnimatedScale', 'AnimatedOpacity', 'AnimatedContainer'],
    realWorldUsage: ['Button feedback', 'Loading state', 'Card expansion'],
    presenterLine:
        'Animation là quá trình thay đổi trạng thái giao diện theo thời gian, giúp thay đổi không bị đột ngột.',
    icon: Icons.auto_awesome,
    accent: _amber,
  ),
  AnimationTopic(
    title: 'Implicit Animation',
    kicker: 'Flutter animates the value change',
    description:
        'With implicit animation, we only update state. Flutter automatically interpolates from the old value to the new value.',
    widgetsUsed: ['AnimatedContainer', 'AnimatedOpacity', 'AnimatedPadding'],
    realWorldUsage: [
      'Signal card expansion',
      'Theme change',
      'Status feedback',
    ],
    presenterLine:
        'Ở ví dụ này, card chuyển từ Searching sang Signal Detected chỉ bằng cách đổi state.',
    icon: Icons.tune,
    accent: _mint,
  ),
  AnimationTopic(
    title: 'AnimatedSwitcher',
    kicker: 'Animate when the child changes',
    description:
        'AnimatedSwitcher is useful when a UI area swaps between states such as searching, detected, connected or completed.',
    widgetsUsed: ['AnimatedSwitcher', 'FadeTransition', 'ScaleTransition'],
    realWorldUsage: [
      'Loading to success',
      'Follow to Following',
      'Scan to Connected',
    ],
    presenterLine:
        'Khi child thay đổi, AnimatedSwitcher tự tạo hiệu ứng chuyển giữa widget cũ và widget mới.',
    icon: Icons.swap_horizontal_circle,
    accent: _blue,
  ),
  AnimationTopic(
    title: 'Explicit Animation',
    kicker: 'Manual playback control',
    description:
        'Explicit animation uses AnimationController so developers can start, stop, repeat, reverse or reset motion manually.',
    widgetsUsed: ['AnimationController', 'Tween', 'AnimatedBuilder'],
    realWorldUsage: ['Bell shake', 'Heartbeat loop', 'Scanning indicator'],
    presenterLine:
        'Explicit Animation phù hợp khi mình cần điều khiển animation chính xác hơn implicit animation.',
    icon: Icons.notifications_active,
    accent: _rose,
  ),
  AnimationTopic(
    title: 'Transition Animation',
    kicker: 'How widgets enter the screen',
    description:
        'Transition widgets animate how UI enters, leaves or transforms. They are often powered by an AnimationController.',
    widgetsUsed: ['SlideTransition', 'FadeTransition', 'ScaleTransition'],
    realWorldUsage: ['Profile reveal', 'Bottom sheet', 'Dialog entrance'],
    presenterLine:
        'Sau khi phát hiện tín hiệu, profile card trượt lên như một màn reveal trong app thật.',
    icon: Icons.vertical_align_top,
    accent: _mint,
  ),
  AnimationTopic(
    title: 'Hero Animation',
    kicker: 'Visual continuity between routes',
    description:
        'Hero connects two screens by animating a shared widget from its old position to a new position using the same tag.',
    widgetsUsed: ['Hero', 'Navigator', 'MaterialPageRoute'],
    realWorldUsage: ['Avatar detail', 'Product preview', 'Photo viewer'],
    presenterLine:
        'Hero giúp người xem hiểu rằng avatar nhỏ và avatar lớn ở màn detail là cùng một đối tượng.',
    icon: Icons.account_circle,
    accent: _blue,
  ),
  AnimationTopic(
    title: 'CustomPainter Radar',
    kicker: 'Drawing motion on Canvas',
    description:
        'CustomPainter lets us draw advanced graphics directly on Canvas, like radar pulses, waves, charts or custom loaders.',
    widgetsUsed: ['CustomPainter', 'Canvas', 'Paint', 'AnimatedBuilder'],
    realWorldUsage: ['Radar pulse', 'Wave loading', 'Animated chart'],
    presenterLine:
        'Radar pulse được tạo bằng cách tăng bán kính vòng tròn và giảm opacity theo thời gian.',
    icon: Icons.radar,
    accent: _pink,
  ),
  AnimationTopic(
    title: 'Match Animation',
    kicker: 'Combining multiple simple motions',
    description:
        'Complex animation often combines position, scale and opacity to create one memorable state change.',
    widgetsUsed: ['AnimatedPositioned', 'ScaleTransition', 'FadeTransition'],
    realWorldUsage: ['Dating match', 'Payment success', 'Achievement unlocked'],
    presenterLine:
        'Một khoảnh khắc match đẹp thường là nhiều animation nhỏ phối hợp với nhau.',
    icon: Icons.favorite_border,
    accent: _rose,
  ),
  AnimationTopic(
    title: 'Building & Publishing',
    kicker: 'From Flutter code to release files',
    description:
        'Building converts Flutter source code into release outputs such as APK, AAB or static Web files for deployment.',
    widgetsUsed: [
      'flutter build apk',
      'flutter build appbundle',
      'flutter build web',
    ],
    realWorldUsage: ['Testing', 'Google Play', 'Web hosting'],
    presenterLine:
        'Sau khi hoàn thành app, Flutter có thể build ra APK để test, AAB để đưa lên Google Play hoặc bản Web.',
    icon: Icons.rocket_launch,
    accent: _amber,
  ),
  AnimationTopic(
    title: 'Animation Libraries',
    kicker: 'Packages that speed up motion work',
    description:
        'Flutter has many animation packages. They help import designer-made motion, write chained effects faster or play vector animation assets.',
    widgetsUsed: ['lottie', 'rive', 'flutter_animate'],
    realWorldUsage: [
      'Designer handoff',
      'Splash animation',
      'Micro-interactions',
    ],
    presenterLine:
        'Ngoài widget có sẵn, Flutter còn có thư viện như Lottie, Rive và flutter_animate để làm animation nhanh và chuyên nghiệp hơn.',
    icon: Icons.extension,
    accent: _blue,
  ),
  AnimationTopic(
    title: 'Advanced Motion Example',
    kicker: 'Timeline, physics and layered effects',
    description:
        'Advanced animation combines timeline orchestration, physics-like curves, canvas drawing and layered UI states to create a polished product moment.',
    widgetsUsed: ['Staggered Animation', 'SpringSimulation', 'ShaderMask'],
    realWorldUsage: [
      'Onboarding sequence',
      'Premium unlock',
      'Data storytelling',
    ],
    presenterLine:
        'Ví dụ nâng cao thường không phải một animation đơn lẻ, mà là nhiều lớp chuyển động chạy theo timeline.',
    icon: Icons.bolt,
    accent: _amber,
  ),
  AnimationTopic(
    title: 'Conclusion',
    kicker: 'Animation is communication',
    description:
        'Animation is not only decoration. It helps users understand state changes, receive feedback and feel a smoother experience.',
    widgetsUsed: [
      'Implicit widgets',
      'Controllers',
      'Transitions',
      'CustomPainter',
    ],
    realWorldUsage: ['Clear feedback', 'Better storytelling', 'Polished UX'],
    presenterLine:
        'Flutter cung cấp công cụ animation từ đơn giản đến nâng cao, đủ để biến UI thành một câu chuyện dễ hiểu.',
    icon: Icons.check_circle,
    accent: _mint,
  ),
];

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  int currentIndex = 0;
  final Map<String, bool> enabledById = {};
  final Map<String, String> codeById = {};

  void nextTopic() {
    setState(() {
      currentIndex = currentIndex == topics.length - 1 ? 0 : currentIndex + 1;
    });
  }

  void previousTopic() {
    if (currentIndex == 0) return;
    setState(() => currentIndex--);
  }

  void setInspectorEnabled(String id, bool enabled) {
    setState(() => enabledById[id] = enabled);
  }

  void setLiveCode(String id, String code) {
    setState(() => codeById[id] = code);
  }

  @override
  Widget build(BuildContext context) {
    final topic = topics[currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AtmosphereBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 920;
                final content = isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: _StageCard(
                              index: currentIndex,
                              topic: topic,
                              enabledById: enabledById,
                              codeById: codeById,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: InfoPanel(
                              topic: topic,
                              currentIndex: currentIndex,
                              total: topics.length,
                              enabledById: enabledById,
                              codeById: codeById,
                              onToggleItem: setInspectorEnabled,
                              onCodeChanged: setLiveCode,
                              onNext: nextTopic,
                              onPrevious: previousTopic,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _StageCard(
                              index: currentIndex,
                              topic: topic,
                              enabledById: enabledById,
                              codeById: codeById,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: InfoPanel(
                              topic: topic,
                              currentIndex: currentIndex,
                              total: topics.length,
                              enabledById: enabledById,
                              codeById: codeById,
                              onToggleItem: setInspectorEnabled,
                              onCodeChanged: setLiveCode,
                              onNext: nextTopic,
                              onPrevious: previousTopic,
                            ),
                          ),
                        ],
                      );

                return Column(
                  children: [
                    _TopBar(
                      currentIndex: currentIndex,
                      total: topics.length,
                      onRestart: () => setState(() => currentIndex = 0),
                    ),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentIndex,
    required this.total,
    required this.onRestart,
  });

  final int currentIndex;
  final int total;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _pink.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.favorite, color: _pink),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Love Alarm Motion Lab',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Flutter Animation Journey',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${currentIndex + 1}/$total',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'Restart',
            onPressed: onRestart,
            icon: const Icon(Icons.replay),
          ),
        ],
      ),
    );
  }
}

class _WebViewChrome extends StatelessWidget {
  const _WebViewChrome({required this.index, required this.topic});

  final int index;
  final AnimationTopic topic;

  @override
  Widget build(BuildContext context) {
    final slug = topic.title
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
      ),
      child: Row(
        children: [
          const _BrowserDot(color: Color(0xFFFF5F57)),
          const SizedBox(width: 7),
          const _BrowserDot(color: Color(0xFFFFBD2E)),
          const SizedBox(width: 7),
          const _BrowserDot(color: Color(0xFF28C840)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _bg.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 14, color: topic.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'https://lovealarm.motion/slide/${index + 1}/$slug',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.web_asset, color: Colors.white54, size: 18),
        ],
      ),
    );
  }
}

class _BrowserDot extends StatelessWidget {
  const _BrowserDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.index,
    required this.topic,
    required this.enabledById,
    required this.codeById,
  });

  final int index;
  final AnimationTopic topic;
  final Map<String, bool> enabledById;
  final Map<String, String> codeById;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: topic.accent.withValues(alpha: 0.16),
              blurRadius: 44,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              _WebViewChrome(index: index, topic: topic),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _StageGrid(accent: topic.accent)),
                    Positioned.fill(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 520),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.96,
                                end: 1,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: LayoutBuilder(
                          key: ValueKey(index),
                          builder: (context, constraints) {
                            final designHeight = math.max(
                              constraints.maxHeight,
                              360.0,
                            );
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: designHeight,
                                child: DemoArea(
                                  index: index,
                                  topic: topic,
                                  enabledById: enabledById,
                                  codeById: codeById,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: _StageBadge(topic: topic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.topic});

  final AnimationTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: topic.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(topic.icon, size: 17, color: topic.accent),
          const SizedBox(width: 8),
          Text(
            topic.kicker,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

List<MotionInspectorItem> _buildInspectorItems(AnimationTopic topic) {
  final widgets = topic.widgetsUsed.map(
    (label) => _detailFor(label, 'Widget', topic.accent),
  );
  final usage = topic.realWorldUsage.map(
    (label) => _detailFor(label, 'Usage', _mint),
  );
  return [...widgets, ...usage];
}

MotionInspectorItem _detailFor(String label, String category, Color accent) {
  final id = _inspectorId(category, label);

  switch (label) {
    case 'AnimatedContainer':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Tự animate các thuộc tính như size, color, padding, border radius khi state thay đổi.',
        code: r'''AnimatedContainer(
  duration: const Duration(milliseconds: 650),
  curve: Curves.easeInOutCubic,
  width: detected ? 320 : 232,
  padding: EdgeInsets.all(detected ? 26 : 20),
  decoration: BoxDecoration(
    color: detected ? const Color(0xFFFFE5EF) : const Color(0xFF283044),
    borderRadius: BorderRadius.circular(detected ? 30 : 18),
  ),
  child: const Text('Signal Detected'),
)''',
        errorHint:
            'Nếu duration quá ngắn hoặc child quá lớn, người xem sẽ thấy giật hoặc overflow.',
        icon: Icons.dashboard_customize,
        accent: accent,
      );
    case 'AnimatedOpacity':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose: 'Ẩn/hiện mềm mại bằng cách animate opacity từ 0 đến 1.',
        code: r'''AnimatedOpacity(
  duration: const Duration(milliseconds: 420),
  opacity: detected ? 1 : 0,
  child: const Text('Someone is nearby'),
)''',
        errorHint:
            'Opacity bằng 0 vẫn chiếm layout. Nếu cần bỏ khỏi layout, kết hợp AnimatedSize hoặc Visibility.',
        icon: Icons.opacity,
        accent: accent,
      );
    case 'AnimatedScale':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Tạo cảm giác widget nảy lên hoặc thu lại mà không cần AnimationController.',
        code: r'''AnimatedScale(
  duration: const Duration(milliseconds: 700),
  curve: Curves.easeOutBack,
  scale: active ? 1 : 0.72,
  child: const Icon(Icons.favorite),
)''',
        errorHint:
            'Scale quá lớn có thể bị cắt nếu parent không đủ không gian.',
        icon: Icons.zoom_out_map,
        accent: accent,
      );
    case 'AnimatedSwitcher':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Animate khi child thay đổi, rất hợp cho trạng thái loading, success, empty hoặc connected.',
        code: r'''AnimatedSwitcher(
  duration: const Duration(milliseconds: 500),
  transitionBuilder: (child, animation) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(opacity: animation, child: child),
    );
  },
  child: Text(status, key: ValueKey(status)),
)''',
        errorHint:
            'Nếu child không có Key khác nhau, Flutter có thể nghĩ đó là cùng một widget và không animate.',
        icon: Icons.swap_calls,
        accent: accent,
      );
    case 'AnimationController':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Điều khiển animation thủ công: start, stop, repeat, reverse hoặc reset.',
        code: r'''late final AnimationController controller;

@override
void initState() {
  super.initState();
  controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  )..repeat(reverse: true);
}

@override
void dispose() {
  controller.dispose();
  super.dispose();
}''',
        errorHint:
            'Quên dispose controller sẽ gây memory leak. Quên TickerProvider sẽ báo lỗi vsync.',
        icon: Icons.play_circle,
        accent: accent,
      );
    case 'Tween':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Chuyển progress 0..1 của controller thành giá trị cụ thể như góc xoay hoặc scale.',
        code: r'''final shake = Tween<double>(begin: -0.16, end: 0.16).animate(
  CurvedAnimation(parent: controller, curve: Curves.easeInOut),
);

Transform.rotate(angle: shake.value, child: bell)''',
        errorHint:
            'Sai kiểu Tween với widget nhận kiểu khác sẽ gây lỗi compile hoặc animation không đúng.',
        icon: Icons.timeline,
        accent: accent,
      );
    case 'AnimatedBuilder':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Rebuild đúng phần UI phụ thuộc animation, giúp animation mượt và ít tốn tài nguyên.',
        code: r'''AnimatedBuilder(
  animation: controller,
  builder: (context, child) {
    return Transform.rotate(
      angle: shake.value,
      child: child,
    );
  },
  child: const Icon(Icons.notifications_active),
)''',
        errorHint:
            'Đặt toàn bộ màn hình trong builder có thể làm rebuild quá nhiều.',
        icon: Icons.precision_manufacturing,
        accent: accent,
      );
    case 'FadeTransition':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Fade widget bằng Animation<double>, thường dùng cùng route hoặc transition controller.',
        code: r'''FadeTransition(
  opacity: fadeAnimation,
  child: profileCard,
)''',
        errorHint:
            'Animation opacity nên nằm trong khoảng 0..1, nếu không sẽ assert trong debug.',
        icon: Icons.blur_on,
        accent: accent,
      );
    case 'ScaleTransition':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Scale widget bằng Animation<double>, hợp cho popup, avatar, match moment.',
        code: r'''ScaleTransition(
  scale: CurvedAnimation(
    parent: controller,
    curve: Curves.easeOutBack,
  ),
  child: const Icon(Icons.favorite),
)''',
        errorHint:
            'Scale lớn có thể làm widget chồng lên nội dung khác nếu không có constraint.',
        icon: Icons.open_in_full,
        accent: accent,
      );
    case 'SlideTransition':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose: 'Cho widget trượt vào/ra màn hình bằng Offset animation.',
        code: r'''SlideTransition(
  position: Tween<Offset>(
    begin: const Offset(0, 0.72),
    end: Offset.zero,
  ).animate(controller),
  child: profileCard,
)''',
        errorHint:
            'Offset là theo kích thước của chính child, không phải pixel tuyệt đối.',
        icon: Icons.vertical_align_top,
        accent: accent,
      );
    case 'Hero':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Liên kết một widget giữa hai route để chuyển màn hình có continuity.',
        code: r'''Hero(
  tag: 'profile-avatar',
  child: CircleAvatar(child: Icon(Icons.person)),
)

Navigator.push(context, MaterialPageRoute(
  builder: (_) => const ProfileDetailScreen(),
));''',
        errorHint:
            'Hai Hero trong cùng một route không được trùng tag, nếu trùng sẽ báo lỗi runtime.',
        icon: Icons.account_circle,
        accent: accent,
      );
    case 'Navigator':
    case 'MaterialPageRoute':
    case 'PageRoute':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Đưa người dùng sang màn detail để Hero có điểm bắt đầu và điểm kết thúc.',
        code: r'''Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => const ProfileDetailScreen(),
  ),
);''',
        errorHint:
            'Gọi Navigator bằng context không còn mounted sau async có thể gây lỗi.',
        icon: Icons.open_in_new,
        accent: accent,
      );
    case 'CustomPainter':
    case 'Canvas':
    case 'Paint':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Tự vẽ radar, chart, wave hoặc hiệu ứng không tiện dựng bằng widget thường.',
        code: r'''class RadarPainter extends CustomPainter {
  RadarPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 * progress;
    canvas.drawCircle(center, radius, Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.pinkAccent.withOpacity(1 - progress));
  }

  @override
  bool shouldRepaint(RadarPainter old) => old.progress != progress;
}''',
        errorHint: 'Nếu shouldRepaint luôn false, animation sẽ không vẽ lại.',
        icon: Icons.brush,
        accent: accent,
      );
    case 'AnimatedPositioned':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose: 'Animate vị trí trong Stack mà không cần controller thủ công.',
        code: r'''AnimatedPositioned(
  duration: const Duration(milliseconds: 650),
  curve: Curves.easeOutCubic,
  left: matched ? 116 : 12,
  child: avatar,
)''',
        errorHint: 'AnimatedPositioned chỉ hoạt động khi parent là Stack.',
        icon: Icons.control_camera,
        accent: accent,
      );
    case 'lottie':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Chạy animation JSON xuất từ After Effects, rất hợp splash, empty state, success state.',
        code: r'''// pubspec.yaml
// lottie: ^3.x

Lottie.asset(
  'assets/love_success.json',
  repeat: true,
  fit: BoxFit.contain,
)''',
        errorHint:
            'Sai asset path hoặc quên khai báo assets trong pubspec.yaml sẽ báo unable to load asset.',
        icon: Icons.movie_filter,
        accent: accent,
      );
    case 'rive':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Chạy animation tương tác từ Rive, có state machine cho hover, click, drag, progress.',
        code: r'''// pubspec.yaml
// rive: ^0.x

RiveAnimation.asset(
  'assets/love_alarm.riv',
  stateMachines: const ['AlarmMachine'],
)''',
        errorHint:
            'Sai tên state machine hoặc file .riv không đúng version sẽ khiến animation không phản hồi.',
        icon: Icons.animation,
        accent: accent,
      );
    case 'flutter_animate':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Viết chuỗi hiệu ứng nhanh bằng extension syntax, hợp micro-interaction và onboarding.',
        code: r'''// pubspec.yaml
// flutter_animate: ^4.x

Text('Signal Detected')
  .animate()
  .fadeIn(duration: 300.ms)
  .slideY(begin: .18, end: 0)
  .scale(begin: const Offset(.92, .92));''',
        errorHint:
            'Quên import package:flutter_animate/flutter_animate.dart thì extension .animate() không tồn tại.',
        icon: Icons.auto_awesome_motion,
        accent: accent,
      );
    case 'Staggered Animation':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Chia một controller thành nhiều khoảng thời gian để từng layer xuất hiện lần lượt.',
        code: r'''final title = CurvedAnimation(
  parent: controller,
  curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
);
final card = CurvedAnimation(
  parent: controller,
  curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
);
final cta = CurvedAnimation(
  parent: controller,
  curve: const Interval(0.65, 1.0, curve: Curves.easeOutBack),
);''',
        errorHint:
            'Interval chồng sai thứ tự làm timeline khó hiểu hoặc element xuất hiện quá sớm.',
        icon: Icons.view_timeline,
        accent: accent,
      );
    case 'SpringSimulation':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Tạo motion có cảm giác vật lý, nảy tự nhiên hơn curve tuyến tính.',
        code: r'''final simulation = SpringSimulation(
  const SpringDescription(mass: 1, stiffness: 160, damping: 13),
  0,
  1,
  0,
);
controller.animateWith(simulation);''',
        errorHint:
            'Cần import package:flutter/physics.dart. Damping quá thấp làm animation rung quá lâu.',
        icon: Icons.waves,
        accent: accent,
      );
    case 'ShaderMask':
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose:
            'Tạo hiệu ứng ánh sáng, shimmer hoặc reveal bằng shader/gradient mask.',
        code: r'''ShaderMask(
  shaderCallback: (rect) => LinearGradient(
    colors: [Colors.white, Colors.pinkAccent, Colors.white],
    stops: [progress - .2, progress, progress + .2],
  ).createShader(rect),
  child: const Text('Love Alarm'),
)''',
        errorHint:
            'Stops phải nằm hợp lệ và tăng dần; nếu không gradient có thể assert trong debug.',
        icon: Icons.gradient,
        accent: accent,
      );
    default:
      return MotionInspectorItem(
        id: id,
        label: label,
        category: category,
        purpose: category == 'Widget'
            ? 'Thành phần kỹ thuật được dùng trong demo này.'
            : 'Tình huống thực tế nơi animation giúp người dùng hiểu trạng thái rõ hơn.',
        code: category == 'Widget'
            ? '''$label(
  // Configure this motion piece for the current slide.
)'''
            : '''// Usage: $label
// Use animation to communicate state, feedback and flow.''',
        errorHint:
            'Nếu trạng thái UI và animation không đồng bộ, người xem sẽ hiểu sai hành động vừa xảy ra.',
        icon: category == 'Widget' ? Icons.widgets : Icons.public,
        accent: accent,
      );
  }
}

class InfoPanel extends StatefulWidget {
  const InfoPanel({
    super.key,
    required this.topic,
    required this.currentIndex,
    required this.total,
    required this.enabledById,
    required this.codeById,
    required this.onToggleItem,
    required this.onCodeChanged,
    required this.onNext,
    required this.onPrevious,
  });

  final AnimationTopic topic;
  final int currentIndex;
  final int total;
  final Map<String, bool> enabledById;
  final Map<String, String> codeById;
  final void Function(String id, bool enabled) onToggleItem;
  final void Function(String id, String code) onCodeChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  State<InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<InfoPanel> {
  String? selectedId;

  @override
  void didUpdateWidget(covariant InfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      selectedId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.currentIndex == widget.total - 1;
    final items = _buildInspectorItems(widget.topic);
    final selected = items.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => items.first,
    );
    selectedId ??= selected.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _panel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressDots(
                total: widget.total,
                currentIndex: widget.currentIndex,
                accent: widget.topic.accent,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.topic.title,
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.topic.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InfoSection(
                        icon: Icons.widgets,
                        title: 'Widgets and libraries',
                        items: items
                            .where((item) => item.category == 'Widget')
                            .toList(),
                        selectedId: selected.id,
                        enabledById: widget.enabledById,
                        accent: widget.topic.accent,
                        onSelect: (item) =>
                            setState(() => selectedId = item.id),
                        onToggle: _toggleItem,
                      ),
                      const SizedBox(height: 12),
                      _InfoSection(
                        icon: Icons.public,
                        title: 'Usage buttons',
                        items: items
                            .where((item) => item.category == 'Usage')
                            .toList(),
                        selectedId: selected.id,
                        enabledById: widget.enabledById,
                        accent: _mint,
                        onSelect: (item) =>
                            setState(() => selectedId = item.id),
                        onToggle: _toggleItem,
                      ),
                      const SizedBox(height: 12),
                      _InspectorDetail(
                        item: selected,
                        enabled: widget.enabledById[selected.id] ?? true,
                        code: widget.codeById[selected.id] ?? selected.code,
                        onCodeChanged: (code) =>
                            widget.onCodeChanged(selected.id, code),
                        onChanged: (value) => setState(() {
                          widget.onToggleItem(selected.id, value);
                        }),
                      ),
                      const SizedBox(height: 12),
                      _PresenterNote(text: widget.topic.presenterLine),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: widget.currentIndex == 0
                        ? null
                        : widget.onPrevious,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: widget.onNext,
                    icon: Icon(isLast ? Icons.replay : Icons.arrow_forward),
                    label: Text(isLast ? 'Restart' : 'Next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.topic.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleItem(MotionInspectorItem item, bool value) {
    setState(() => selectedId = item.id);
    widget.onToggleItem(item.id, value);
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.total,
    required this.currentIndex,
    required this.accent,
  });

  final int total;
  final int currentIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final active = index == currentIndex;
        final passed = index < currentIndex;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            height: 5,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active || passed
                  ? accent
                  : Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.selectedId,
    required this.enabledById,
    required this.accent,
    required this.onSelect,
    required this.onToggle,
  });

  final IconData icon;
  final String title;
  final List<MotionInspectorItem> items;
  final String selectedId;
  final Map<String, bool> enabledById;
  final Color accent;
  final ValueChanged<MotionInspectorItem> onSelect;
  final void Function(MotionInspectorItem item, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelSoft.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return _InspectorChip(
                item: item,
                selected: selectedId == item.id,
                enabled: enabledById[item.id] ?? true,
                onSelect: () => onSelect(item),
                onToggle: (value) => onToggle(item, value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InspectorChip extends StatelessWidget {
  const _InspectorChip({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onToggle,
  });

  final MotionInspectorItem item;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? Colors.white : Colors.white38;
    final chipColor = selected
        ? item.accent.withValues(alpha: enabled ? 0.26 : 0.10)
        : item.accent.withValues(alpha: enabled ? 0.12 : 0.05);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      constraints: const BoxConstraints(minHeight: 46, maxWidth: 278),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? item.accent.withValues(alpha: 0.82)
              : item.accent.withValues(alpha: enabled ? 0.28 : 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 4,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: enabled ? item.accent : Colors.white30,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.68,
                  child: Switch(
                    value: enabled,
                    activeThumbColor: item.accent,
                    activeTrackColor: item.accent.withValues(alpha: 0.28),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white10,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: onToggle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InspectorDetail extends StatefulWidget {
  const _InspectorDetail({
    required this.item,
    required this.enabled,
    required this.code,
    required this.onCodeChanged,
    required this.onChanged,
  });

  final MotionInspectorItem item;
  final bool enabled;
  final String code;
  final ValueChanged<String> onCodeChanged;
  final ValueChanged<bool> onChanged;

  @override
  State<_InspectorDetail> createState() => _InspectorDetailState();
}

class _InspectorDetailState extends State<_InspectorDetail> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant _InspectorDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        (widget.code != controller.text && oldWidget.code != widget.code)) {
      controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livePatch = _parseLiveCode(widget.item, controller.text);
    final enabled = widget.enabled;
    final consoleColor = !enabled || livePatch.hasError ? _rose : _mint;
    final consoleText = !enabled
        ? widget.item.category == 'Widget'
              ? 'MissingDependencyError: ${widget.item.label} was removed from the live web view. ${widget.item.errorHint}'
              : 'FeatureDisabledWarning: ${widget.item.label} is turned off for this scenario.'
        : livePatch.hasError
        ? 'LiveCodeError: ${livePatch.error}'
        : widget.item.category == 'Widget'
        ? 'Status: OK. Editing this code updates the live web view on the left.'
        : 'Status: OK. ${widget.item.label} is enabled for this scenario.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.item.accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.item.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      widget.item.category == 'Widget'
                          ? 'Live code editor'
                          : 'Usage preview',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: enabled,
                activeThumbColor: widget.item.accent,
                activeTrackColor: widget.item.accent.withValues(alpha: 0.30),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
                onChanged: widget.onChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.item.purpose,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E15),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: livePatch.hasError
                    ? _rose.withValues(alpha: 0.36)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: TextField(
              controller: controller,
              minLines: 7,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              onChanged: widget.onCodeChanged,
              cursorColor: widget.item.accent,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.45,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(13),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: consoleColor.withValues(
                alpha: enabled && !livePatch.hasError ? 0.10 : 0.14,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: consoleColor.withValues(alpha: 0.32)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  enabled && !livePatch.hasError
                      ? Icons.check_circle
                      : Icons.error,
                  color: consoleColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    consoleText,
                    style: TextStyle(
                      color: consoleColor,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenterNote extends StatelessWidget {
  const _PresenterNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.record_voice_over, color: _amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoArea extends StatelessWidget {
  const DemoArea({
    super.key,
    required this.index,
    required this.topic,
    required this.enabledById,
    required this.codeById,
  });

  final int index;
  final AnimationTopic topic;
  final Map<String, bool> enabledById;
  final Map<String, String> codeById;

  @override
  Widget build(BuildContext context) {
    final disabledWidgets = _disabledLabels(
      enabledById,
      'Widget',
      topic.widgetsUsed,
    );
    final disabledUsage = _disabledLabels(
      enabledById,
      'Usage',
      topic.realWorldUsage,
    );
    final livePatch = _activeLiveCodePatch(topic, codeById);

    if (disabledWidgets.isNotEmpty) {
      return _LivePreviewError(topic: topic, disabledWidgets: disabledWidgets);
    }

    if (livePatch?.hasError ?? false) {
      return _LiveCodeError(patch: livePatch!);
    }

    final demo = livePatch == null
        ? switch (index) {
            0 => const IntroAnimationDemo(),
            1 => const WhatIsAnimationDemo(),
            2 => const ImplicitAnimationDemo(),
            3 => const AnimatedSwitcherDemo(),
            4 => const BellShakeDemo(),
            5 => const ProfileSlideDemo(),
            6 => const HeroAnimationDemo(),
            7 => const RadarPainterDemo(),
            8 => const MatchAnimationDemo(),
            9 => const BuildPublishingDemo(),
            10 => const AnimationLibrariesDemo(),
            11 => const AdvancedMotionDemo(),
            12 => const ConclusionDemo(),
            _ => const IntroAnimationDemo(),
          }
        : _LiveCodeRenderedPreview(patch: livePatch);

    if (disabledUsage.isEmpty && livePatch == null) return demo;

    return Stack(
      children: [
        Positioned.fill(child: demo),
        if (livePatch != null)
          Positioned(
            left: 18,
            right: 18,
            top: 18,
            child: _LiveCodeOutputOverlay(patch: livePatch),
          ),
        if (disabledUsage.isNotEmpty)
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: _RuntimeWarningOverlay(disabledUsage: disabledUsage),
          ),
      ],
    );
  }
}

class _LiveCodeRenderedPreview extends StatelessWidget {
  const _LiveCodeRenderedPreview({required this.patch});

  final LiveCodePatch patch;

  @override
  Widget build(BuildContext context) {
    final label = patch.text ?? patch.item.label;
    final duration = Duration(milliseconds: patch.durationMs ?? 450);
    final slideBegin = patch.slideYBegin ?? 0.16;
    final beginScale = Offset(patch.scaleX ?? 0.92, patch.scaleY ?? 0.92);

    final labelName = patch.item.label;
    if (labelName == 'AnimatedContainer' || labelName == 'AnimatedPadding') {
      return _ContainerCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'AnimatedOpacity' || labelName == 'FadeTransition') {
      return _OpacityCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'AnimatedScale' || labelName == 'ScaleTransition') {
      return _AnimatedScaleCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'AnimatedSwitcher') {
      return _SwitcherCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'AnimationController' ||
        labelName == 'Tween' ||
        labelName == 'AnimatedBuilder' ||
        labelName == 'Staggered Animation' ||
        labelName == 'SpringSimulation') {
      return _TimelineCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'SlideTransition') {
      return _SlideCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'Hero' ||
        labelName == 'Navigator' ||
        labelName == 'MaterialPageRoute' ||
        labelName == 'PageRoute') {
      return _HeroCodePreview(patch: patch);
    }
    if (labelName == 'CustomPainter' ||
        labelName == 'Canvas' ||
        labelName == 'Paint') {
      return _PainterCodePreview(patch: patch);
    }
    if (labelName == 'AnimatedPositioned') {
      return _PositionedCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'lottie' ||
        labelName == 'rive' ||
        labelName == 'flutter_animate') {
      return _PackageCodePreview(patch: patch, duration: duration);
    }
    if (labelName == 'ShaderMask') {
      return _ShaderCodePreview(patch: patch, duration: duration);
    }
    if (patch.item.category == 'Usage') {
      return _UsageCodePreview(patch: patch);
    }

    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patch.code),
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final dy = (1 - value) * slideBegin * 180;
          final scaleX = beginScale.dx + (1 - beginScale.dx) * value;
          final scaleY = beginScale.dy + (1 - beginScale.dy) * value;
          return Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scaleX: scaleX,
                scaleY: scaleY,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: patch.item.accent.withValues(alpha: 0.46),
            ),
            boxShadow: [
              BoxShadow(
                color: patch.item.accent.withValues(alpha: 0.24),
                blurRadius: 42,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: patch.item.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: patch.item.accent.withValues(alpha: 0.38),
                  ),
                ),
                child: Icon(
                  patch.item.icon,
                  color: patch.item.accent,
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                patch.item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 18),
              _LiveCodeMetricRow(
                durationMs: patch.durationMs,
                slideYBegin: patch.slideYBegin,
                scaleX: patch.scaleX,
                scaleY: patch.scaleY,
                scaleBegin: patch.scaleBegin,
                scaleEnd: patch.scaleEnd,
                accent: patch.item.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContainerCodePreview extends StatelessWidget {
  const _ContainerCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final width = (patch.width ?? 260).clamp(120, 380).toDouble();
    final height = (patch.height ?? 160).clamp(90, 260).toDouble();
    final padding = patch.padding ?? 18;
    final radius = patch.radius ?? 24;
    final color = patch.color ?? patch.item.accent.withValues(alpha: 0.22);

    return Center(
      child: AnimatedContainer(
        key: ValueKey(patch.code),
        duration: duration,
        curve: Curves.easeInOutCubic,
        width: width,
        height: height,
        padding: EdgeInsets.all(padding.clamp(0, 36).toDouble()),
        decoration: BoxDecoration(
          color: color.withValues(alpha: color == Colors.white ? 0.88 : 0.78),
          borderRadius: BorderRadius.circular(radius.clamp(0, 60).toDouble()),
          border: Border.all(color: patch.item.accent.withValues(alpha: 0.52)),
          boxShadow: [
            BoxShadow(
              color: patch.item.accent.withValues(alpha: 0.22),
              blurRadius: 34,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              patch.icon ?? patch.item.icon,
              color: patch.item.accent,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              patch.text ?? patch.item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'w ${width.toStringAsFixed(0)} · h ${height.toStringAsFixed(0)} · r ${radius.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpacityCodePreview extends StatelessWidget {
  const _OpacityCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final begin = patch.opacityBegin ?? 0.2;
    final end = patch.opacityEnd ?? 1;
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patch.code),
        tween: Tween(begin: begin, end: end),
        duration: duration,
        curve: Curves.easeOut,
        builder: (context, opacity, child) {
          return Opacity(opacity: opacity.clamp(0, 1), child: child);
        },
        child: _LivePreviewCard(
          patch: patch,
          title: patch.text ?? patch.item.label,
          subtitle:
              'opacity: ${begin.toStringAsFixed(2)} -> ${end.toStringAsFixed(2)}',
        ),
      ),
    );
  }
}

class _SwitcherCodePreview extends StatefulWidget {
  const _SwitcherCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  State<_SwitcherCodePreview> createState() => _SwitcherCodePreviewState();
}

class _SwitcherCodePreviewState extends State<_SwitcherCodePreview> {
  bool alt = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(widget.duration, (_) {
      if (mounted) setState(() => alt = !alt);
    });
  }

  @override
  void didUpdateWidget(covariant _SwitcherCodePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      timer?.cancel();
      timer = Timer.periodic(widget.duration, (_) {
        if (mounted) setState(() => alt = !alt);
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.patch.text ?? 'Signal Detected';
    return Center(
      child: AnimatedSwitcher(
        duration: widget.duration,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _LivePreviewCard(
          key: ValueKey(alt),
          patch: widget.patch,
          title: alt ? primary : 'Searching...',
          subtitle: 'AnimatedSwitcher child changed',
        ),
      ),
    );
  }
}

class _TimelineCodePreview extends StatelessWidget {
  const _TimelineCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patch.code),
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return _LivePreviewCard(
            patch: patch,
            title: patch.text ?? patch.item.label,
            subtitle: 'controller progress ${(value * 100).round()}%',
            progress: value,
          );
        },
      ),
    );
  }
}

class _SlideCodePreview extends StatelessWidget {
  const _SlideCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final offsetY = patch.scaleY ?? patch.slideYBegin ?? 0.7;
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patch.code),
        tween: Tween(begin: offsetY, end: 0),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, y, child) {
          return Transform.translate(offset: Offset(0, y * 160), child: child);
        },
        child: _LivePreviewCard(
          patch: patch,
          title: patch.text ?? patch.item.label,
          subtitle: 'Offset.y ${offsetY.toStringAsFixed(2)} -> 0.00',
        ),
      ),
    );
  }
}

class _HeroCodePreview extends StatelessWidget {
  const _HeroCodePreview({required this.patch});

  final LiveCodePatch patch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _LivePreviewCard(
        patch: patch,
        title: patch.text ?? 'Hero route preview',
        subtitle: 'shared tag transition ready',
        iconSize: 58,
      ),
    );
  }
}

class _PainterCodePreview extends StatelessWidget {
  const _PainterCodePreview({required this.patch});

  final LiveCodePatch patch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(280, 280),
        painter: RadarPainter(0.72),
        child: SizedBox(
          width: 280,
          height: 280,
          child: Center(
            child: _LivePreviewCard(
              patch: patch,
              title: patch.text ?? patch.item.label,
              subtitle: 'Canvas/Paint live drawing',
              compact: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionedCodePreview extends StatelessWidget {
  const _PositionedCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final left = patch.width ?? 116;
    return Center(
      child: SizedBox(
        width: 360,
        height: 230,
        child: Stack(
          children: [
            AnimatedPositioned(
              key: ValueKey(patch.code),
              duration: duration,
              curve: Curves.easeOutCubic,
              left: left.clamp(0, 210).toDouble(),
              top: 54,
              child: _Avatar(
                size: 96,
                color: patch.item.accent,
                icon: patch.icon ?? patch.item.icon,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'left: ${left.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCodePreview extends StatelessWidget {
  const _PackageCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patch.code),
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        curve: Curves.easeOutBack,
        builder: (context, value, child) =>
            Transform.scale(scale: 0.82 + value * 0.18, child: child),
        child: _LivePreviewCard(
          patch: patch,
          title: patch.text ?? patch.item.label,
          subtitle: 'package asset/state machine preview',
          iconSize: 58,
        ),
      ),
    );
  }
}

class _ShaderCodePreview extends StatelessWidget {
  const _ShaderCodePreview({required this.patch, required this.duration});

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patch.code),
        tween: Tween(begin: -1, end: 1),
        duration: duration,
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: const [Colors.white, _amber, Colors.white],
              stops: [
                (value - .2).clamp(0, 1).toDouble(),
                value.clamp(0, 1).toDouble(),
                (value + .2).clamp(0, 1).toDouble(),
              ],
            ).createShader(rect),
            child: child,
          );
        },
        child: Text(
          patch.text ?? 'Love Alarm',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _UsageCodePreview extends StatelessWidget {
  const _UsageCodePreview({required this.patch});

  final LiveCodePatch patch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _LivePreviewCard(
        patch: patch,
        title: patch.text ?? patch.item.label,
        subtitle: 'feature scenario is live in this web view',
      ),
    );
  }
}

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({
    super.key,
    required this.patch,
    required this.title,
    required this.subtitle,
    this.progress,
    this.compact = false,
    this.iconSize = 46,
  });

  final LiveCodePatch patch;
  final String title;
  final String subtitle;
  final double? progress;
  final bool compact;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 220 : 360,
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: patch.item.accent.withValues(alpha: 0.46)),
        boxShadow: [
          BoxShadow(
            color: patch.item.accent.withValues(alpha: 0.24),
            blurRadius: 42,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 74 : 96,
            height: compact ? 74 : 96,
            decoration: BoxDecoration(
              color: patch.item.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: patch.item.accent.withValues(alpha: 0.38),
              ),
            ),
            child: Icon(
              patch.icon ?? patch.item.icon,
              color: patch.item.accent,
              size: iconSize,
            ),
          ),
          SizedBox(height: compact ? 10 : 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 19 : 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(patch.item.accent),
              ),
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: 18),
            _LiveCodeMetricRow(
              durationMs: patch.durationMs,
              slideYBegin: patch.slideYBegin,
              scaleX: patch.scaleX,
              scaleY: patch.scaleY,
              scaleBegin: patch.scaleBegin,
              scaleEnd: patch.scaleEnd,
              accent: patch.item.accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedScaleCodePreview extends StatelessWidget {
  const _AnimatedScaleCodePreview({
    required this.patch,
    required this.duration,
  });

  final LiveCodePatch patch;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final begin = patch.scaleBegin ?? 1;
    final end = patch.scaleEnd ?? 1;
    final icon = patch.icon ?? Icons.favorite;

    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patch.code),
        tween: Tween(begin: begin, end: end),
        duration: duration,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: patch.item.accent.withValues(alpha: 0.46),
            ),
            boxShadow: [
              BoxShadow(
                color: patch.item.accent.withValues(alpha: 0.24),
                blurRadius: 42,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: patch.item.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: patch.item.accent.withValues(alpha: 0.38),
                  ),
                ),
                child: Icon(icon, color: patch.item.accent, size: 58),
              ),
              const SizedBox(height: 18),
              const Text(
                'AnimatedScale',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'scale: ${begin.toStringAsFixed(2)} -> ${end.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 18),
              _LiveCodeMetricRow(
                durationMs: patch.durationMs,
                slideYBegin: patch.slideYBegin,
                scaleX: patch.scaleX,
                scaleY: patch.scaleY,
                scaleBegin: patch.scaleBegin,
                scaleEnd: patch.scaleEnd,
                accent: patch.item.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveCodeMetricRow extends StatelessWidget {
  const _LiveCodeMetricRow({
    required this.durationMs,
    required this.slideYBegin,
    required this.scaleX,
    required this.scaleY,
    required this.scaleBegin,
    required this.scaleEnd,
    required this.accent,
  });

  final int? durationMs;
  final double? slideYBegin;
  final double? scaleX;
  final double? scaleY;
  final double? scaleBegin;
  final double? scaleEnd;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('duration', durationMs == null ? 'auto' : '${durationMs}ms'),
      (
        'slideY',
        slideYBegin == null ? 'auto' : slideYBegin!.toStringAsFixed(2),
      ),
      (
        'scale',
        scaleBegin != null && scaleEnd != null
            ? '${scaleBegin!.toStringAsFixed(2)} -> ${scaleEnd!.toStringAsFixed(2)}'
            : scaleX == null || scaleY == null
            ? 'auto'
            : '${scaleX!.toStringAsFixed(2)}, ${scaleY!.toStringAsFixed(2)}',
      ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: metrics.map((metric) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.26)),
          ),
          child: Text(
            '${metric.$1}: ${metric.$2}',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        );
      }).toList(),
    );
  }
}

class _LiveCodeError extends StatelessWidget {
  const _LiveCodeError({required this.patch});

  final LiveCodePatch patch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 430,
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF230F19).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _rose.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(color: _rose.withValues(alpha: 0.24), blurRadius: 42),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.code_off, color: _rose, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live Code Rebuild Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Không thể update preview từ code của ${patch.item.label}.',
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 10),
            _ErrorLine(
              label: 'Error',
              value: patch.error ?? 'Unknown live code error',
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _rose.withValues(alpha: 0.28)),
              ),
              child: Text(
                'LiveCodeError: ${patch.error}',
                style: const TextStyle(
                  color: _rose,
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCodeOutputOverlay extends StatelessWidget {
  const _LiveCodeOutputOverlay({required this.patch});

  final LiveCodePatch patch;

  @override
  Widget build(BuildContext context) {
    final title = patch.text ?? patch.item.label;
    final duration = patch.durationMs == null
        ? 'auto'
        : '${patch.durationMs}ms';
    final slide = patch.slideYBegin == null
        ? 'none'
        : patch.slideYBegin!.toStringAsFixed(2);
    final scale = patch.scaleX == null || patch.scaleY == null
        ? 'none'
        : '${patch.scaleX!.toStringAsFixed(2)}, ${patch.scaleY!.toStringAsFixed(2)}';

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _bg.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: patch.item.accent.withValues(alpha: 0.36)),
          boxShadow: [
            BoxShadow(
              color: patch.item.accent.withValues(alpha: 0.16),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bolt, color: patch.item.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live code: duration $duration · slideY $slide · scale $scale',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePreviewError extends StatelessWidget {
  const _LivePreviewError({required this.topic, required this.disabledWidgets});

  final AnimationTopic topic;
  final List<String> disabledWidgets;

  @override
  Widget build(BuildContext context) {
    final missing = disabledWidgets.join(', ');
    final first = disabledWidgets.first;
    final detail = _detailFor(first, 'Widget', topic.accent);

    return Center(
      child: Container(
        width: 430,
        constraints: const BoxConstraints(maxWidth: 430),
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF230F19).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _rose.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(color: _rose.withValues(alpha: 0.24), blurRadius: 42),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _rose.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.error, color: _rose),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Live Preview Build Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Không thể render slide "${topic.title}" vì bạn đã tắt dependency bắt buộc:',
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 10),
            _ErrorLine(label: 'Missing', value: missing),
            const SizedBox(height: 8),
            _ErrorLine(label: 'Reason', value: detail.errorHint),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _rose.withValues(alpha: 0.28)),
              ),
              child: Text(
                'MissingDependencyError: $missing is disabled. Enable it on the right panel to rebuild this live web view.',
                style: const TextStyle(
                  color: _rose,
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _RuntimeWarningOverlay extends StatelessWidget {
  const _RuntimeWarningOverlay({required this.disabledUsage});

  final List<String> disabledUsage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.36)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, color: _amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Runtime warning: ${disabledUsage.join(', ')} is disabled, so this web view keeps rendering the widget but the selected feature path is inactive.',
              style: const TextStyle(
                color: _amber,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntroAnimationDemo extends StatefulWidget {
  const IntroAnimationDemo({super.key});

  @override
  State<IntroAnimationDemo> createState() => _IntroAnimationDemoState();
}

class _IntroAnimationDemoState extends State<IntroAnimationDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulse = 0.95 + math.sin(controller.value * math.pi * 2) * 0.08;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: pulse,
                child: CustomPaint(
                  size: const Size(250, 250),
                  painter: _IntroPulsePainter(controller.value),
                  child: const SizedBox(
                    width: 250,
                    height: 250,
                    child: Center(
                      child: Icon(Icons.favorite, color: _pink, size: 92),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Flutter Animation Journey',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Live demos instead of static slides',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WhatIsAnimationDemo extends StatefulWidget {
  const WhatIsAnimationDemo({super.key});

  @override
  State<WhatIsAnimationDemo> createState() => _WhatIsAnimationDemoState();
}

class _WhatIsAnimationDemoState extends State<WhatIsAnimationDemo> {
  bool expanded = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      if (mounted) setState(() => expanded = !expanded);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 760),
        curve: Curves.easeInOutCubic,
        width: expanded ? 250 : 148,
        height: expanded ? 250 : 148,
        decoration: BoxDecoration(
          color: Color.lerp(_panelSoft, _amber, expanded ? 0.18 : 0.05),
          borderRadius: BorderRadius.circular(expanded ? 60 : 34),
          border: Border.all(
            color: _amber.withValues(alpha: expanded ? 0.65 : 0.22),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _amber.withValues(alpha: expanded ? 0.34 : 0.10),
              blurRadius: expanded ? 52 : 18,
            ),
          ],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 760),
          curve: Curves.easeInOutBack,
          scale: expanded ? 1 : 0.72,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 620),
            opacity: expanded ? 1 : 0.62,
            child: const Icon(Icons.favorite, size: 96, color: _amber),
          ),
        ),
      ),
    );
  }
}

class ImplicitAnimationDemo extends StatefulWidget {
  const ImplicitAnimationDemo({super.key});

  @override
  State<ImplicitAnimationDemo> createState() => _ImplicitAnimationDemoState();
}

class _ImplicitAnimationDemoState extends State<ImplicitAnimationDemo> {
  bool detected = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (mounted) setState(() => detected = !detected);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => detected = !detected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 680),
          curve: Curves.easeInOutCubic,
          width: detected ? 320 : 232,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: EdgeInsets.all(detected ? 26 : 20),
          decoration: BoxDecoration(
            color: detected ? const Color(0xFFFFE5EF) : const Color(0xFF283044),
            borderRadius: BorderRadius.circular(detected ? 30 : 18),
            border: Border.all(color: detected ? _pink : Colors.white24),
            boxShadow: [
              BoxShadow(
                color: (detected ? _pink : _mint).withValues(
                  alpha: detected ? 0.34 : 0.12,
                ),
                blurRadius: detected ? 45 : 18,
                spreadRadius: detected ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                child: Icon(
                  detected ? Icons.favorite : Icons.search,
                  key: ValueKey(detected),
                  color: detected ? _pink : _mint,
                  size: detected ? 62 : 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                detected ? 'Signal Detected' : 'Searching...',
                style: TextStyle(
                  color: detected ? const Color(0xFF8A1746) : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeOutCubic,
                child: detected
                    ? const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Someone is nearby',
                          style: TextStyle(
                            color: Color(0xFF8A1746),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedSwitcherDemo extends StatefulWidget {
  const AnimatedSwitcherDemo({super.key});

  @override
  State<AnimatedSwitcherDemo> createState() => _AnimatedSwitcherDemoState();
}

class _AnimatedSwitcherDemoState extends State<AnimatedSwitcherDemo> {
  int state = 0;
  Timer? timer;

  final labels = const [
    'Searching...',
    'Signal Detected',
    'Someone likes you nearby',
  ];
  final buttonLabels = const ['Scan', 'Ringing', 'Connected'];
  final icons = const [
    Icons.search,
    Icons.notifications_active,
    Icons.favorite,
  ];
  final colors = const [_mint, _amber, _pink];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(milliseconds: 1450),
      (_) => changeState(),
    );
  }

  void changeState() {
    if (mounted) setState(() => state = (state + 1) % labels.length);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: changeState,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Container(
                key: ValueKey(state),
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[state].withValues(alpha: 0.13),
                  border: Border.all(
                    color: colors[state].withValues(alpha: 0.58),
                    width: 1.5,
                  ),
                ),
                child: Icon(icons[state], color: colors[state], size: 78),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 430),
              child: Text(
                labels[state],
                key: ValueKey(labels[state]),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              child: Container(
                key: ValueKey(buttonLabels[state]),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors[state],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  buttonLabels[state],
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BellShakeDemo extends StatefulWidget {
  const BellShakeDemo({super.key});

  @override
  State<BellShakeDemo> createState() => _BellShakeDemoState();
}

class _BellShakeDemoState extends State<BellShakeDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> shake;
  late final Animation<double> glow;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..repeat(reverse: true);
    shake = Tween<double>(
      begin: -0.16,
      end: 0.16,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    glow = Tween<double>(
      begin: 0.18,
      end: 0.46,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Container(
            width: 226,
            height: 226,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rose.withValues(alpha: 0.10),
              boxShadow: [
                BoxShadow(
                  color: _rose.withValues(alpha: glow.value),
                  blurRadius: 55,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Transform.rotate(angle: shake.value, child: child),
          );
        },
        child: const Icon(Icons.notifications_active, size: 116, color: _rose),
      ),
    );
  }
}

class ProfileSlideDemo extends StatefulWidget {
  const ProfileSlideDemo({super.key});

  @override
  State<ProfileSlideDemo> createState() => _ProfileSlideDemoState();
}

class _ProfileSlideDemoState extends State<ProfileSlideDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<Offset> slide;
  late final Animation<double> fade;
  late final Animation<double> scale;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    slide = Tween<Offset>(begin: const Offset(0, 0.72), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0, 0.76, curve: Curves.easeOutCubic),
          ),
        );
    fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.08, 0.70, curve: Curves.easeOut),
    );
    scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.15, 0.80, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: const _ProfileCard(compact: false),
          ),
        ),
      ),
    );
  }
}

class HeroAnimationDemo extends StatelessWidget {
  const HeroAnimationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileDetailScreen(),
                  ),
                );
              },
              child: const _ProfileCard(compact: true),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileDetailScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('View Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AtmosphereBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const Spacer(),
                  const Hero(
                    tag: 'hero-profile-avatar',
                    child: _Avatar(size: 190),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Mina is nearby',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hero Animation keeps visual continuity while navigating between screens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _blue.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: _pink),
                        SizedBox(width: 8),
                        Text(
                          'Signal strength 94%',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarPainterDemo extends StatefulWidget {
  const RadarPainterDemo({super.key});

  @override
  State<RadarPainterDemo> createState() => _RadarPainterDemoState();
}

class _RadarPainterDemoState extends State<RadarPainterDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(300, 300),
            painter: RadarPainter(controller.value),
            child: const SizedBox(
              width: 300,
              height: 300,
              child: Center(
                child: Icon(Icons.favorite, color: _pink, size: 70),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MatchAnimationDemo extends StatefulWidget {
  const MatchAnimationDemo({super.key});

  @override
  State<MatchAnimationDemo> createState() => _MatchAnimationDemoState();
}

class _MatchAnimationDemoState extends State<MatchAnimationDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> avatars;
  late final Animation<double> heart;
  late final Animation<double> textFade;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    avatars = CurvedAnimation(
      parent: controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    heart = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.44, 0.82, curve: Curves.elasticOut),
    );
    textFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.62, 1, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Center(
          child: SizedBox(
            width: 340,
            height: 310,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 14 + avatars.value * 72,
                  child: const _Avatar(
                    size: 96,
                    color: _mint,
                    icon: Icons.person,
                  ),
                ),
                Positioned(
                  right: 14 + avatars.value * 72,
                  child: const _Avatar(
                    size: 96,
                    color: _blue,
                    icon: Icons.person_2,
                  ),
                ),
                Transform.scale(
                  scale: heart.value,
                  child: Container(
                    width: 106,
                    height: 106,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pink.withValues(alpha: 0.18),
                      border: Border.all(color: _pink.withValues(alpha: 0.48)),
                    ),
                    child: const Icon(Icons.favorite, color: _pink, size: 62),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  child: Opacity(
                    opacity: textFade.value,
                    child: const Text(
                      "It's a Match!",
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BuildPublishingDemo extends StatefulWidget {
  const BuildPublishingDemo({super.key});

  @override
  State<BuildPublishingDemo> createState() => _BuildPublishingDemoState();
}

class _BuildPublishingDemoState extends State<BuildPublishingDemo> {
  int step = 0;
  Timer? timer;

  final steps = const [
    (Icons.code, 'Code'),
    (Icons.construction, 'Build'),
    (Icons.android, 'APK/AAB'),
    (Icons.storefront, 'Store'),
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 980), (_) {
      if (mounted) setState(() => step = (step + 1) % steps.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 14,
              children: List.generate(steps.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Icon(
                    Icons.arrow_forward,
                    color: Colors.white38,
                    size: 22,
                  );
                }
                final itemIndex = index ~/ 2;
                final active = itemIndex == step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: active ? _amber : _panelSoft,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: active ? _amber : Colors.white24),
                    boxShadow: [
                      if (active)
                        BoxShadow(
                          color: _amber.withValues(alpha: 0.35),
                          blurRadius: 34,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        steps[itemIndex].$1,
                        color: active ? Colors.black : Colors.white70,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[itemIndex].$2,
                        style: TextStyle(
                          color: active ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            const _CommandLine(text: 'flutter build apk --release'),
            const SizedBox(height: 8),
            const _CommandLine(text: 'flutter build appbundle --release'),
            const SizedBox(height: 8),
            const _CommandLine(text: 'flutter build web'),
          ],
        ),
      ),
    );
  }
}

class AnimationLibrariesDemo extends StatefulWidget {
  const AnimationLibrariesDemo({super.key, this.livePatch});

  final LiveCodePatch? livePatch;

  @override
  State<AnimationLibrariesDemo> createState() => _AnimationLibrariesDemoState();
}

class _AnimationLibrariesDemoState extends State<AnimationLibrariesDemo> {
  int active = 0;
  Timer? timer;

  final libraries = const [
    (Icons.movie_filter, 'Lottie', _pink, 'JSON motion'),
    (Icons.animation, 'Rive', _mint, 'Interactive state'),
    (Icons.auto_awesome_motion, 'Animate', _amber, 'Chained effects'),
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted) setState(() => active = (active + 1) % libraries.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: List.generate(libraries.length, (index) {
                final library = libraries[index];
                final selected = index == active;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  width: selected ? 142 : 126,
                  height: selected ? 144 : 126,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: library.$3.withValues(alpha: selected ? 0.24 : 0.10),
                    borderRadius: BorderRadius.circular(selected ? 28 : 22),
                    border: Border.all(
                      color: library.$3.withValues(
                        alpha: selected ? 0.72 : 0.26,
                      ),
                    ),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: library.$3.withValues(alpha: 0.30),
                          blurRadius: 34,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        library.$1,
                        color: library.$3,
                        size: selected ? 38 : 30,
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          library.$2,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Center(
                          child: Text(
                            library.$4,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              child: _LibraryPreviewBar(
                key: ValueKey(active),
                name: widget.livePatch?.text ?? libraries[active].$2,
                color: widget.livePatch?.item.accent ?? libraries[active].$3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryPreviewBar extends StatelessWidget {
  const _LibraryPreviewBar({
    super.key,
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.play_arrow, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$name preview',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: 0.74,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdvancedMotionDemo extends StatefulWidget {
  const AdvancedMotionDemo({super.key});

  @override
  State<AdvancedMotionDemo> createState() => _AdvancedMotionDemoState();
}

class _AdvancedMotionDemoState extends State<AdvancedMotionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> titleIn;
  late final Animation<double> cardIn;
  late final Animation<double> beamIn;
  late final Animation<double> ctaIn;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    titleIn = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.00, 0.28, curve: Curves.easeOutCubic),
    );
    cardIn = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.18, 0.58, curve: Curves.easeOutBack),
    );
    beamIn = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.42, 0.78, curve: Curves.easeInOutCubic),
    );
    ctaIn = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.68, 1.00, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Center(
          child: SizedBox(
            width: 390,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AdvancedBeamPainter(beamIn.value),
                  ),
                ),
                Positioned(
                  top: 20,
                  child: Opacity(
                    opacity: titleIn.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - titleIn.value)),
                      child: const Text(
                        'Timeline Orchestration',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.72 + cardIn.value * 0.28,
                  child: Opacity(
                    opacity: cardIn.value.clamp(0, 1),
                    child: Container(
                      width: 230,
                      height: 136,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _panel.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: _amber.withValues(alpha: 0.46),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _amber.withValues(alpha: 0.22),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_open,
                            color: _amber,
                            size: 42 + ctaIn.value * 8,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Premium motion unlocked',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 26,
                  child: Transform.scale(
                    scale: ctaIn.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _amber,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdvancedBeamPainter extends CustomPainter {
  const _AdvancedBeamPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (math.pi * 2 / 8) * i;
      final start = Offset(
        center.dx + math.cos(angle) * 58,
        center.dy + math.sin(angle) * 58,
      );
      final end = Offset(
        center.dx + math.cos(angle) * (58 + progress * 110),
        center.dy + math.sin(angle) * (58 + progress * 110),
      );
      paint.color = [
        _amber,
        _pink,
        _mint,
        _blue,
      ][i % 4].withValues(alpha: (1 - progress * 0.55).clamp(0.2, 1));
      canvas.drawLine(start, end, paint);
      canvas.drawCircle(
        end,
        3 + progress * 3,
        paint..style = PaintingStyle.fill,
      );
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedBeamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConclusionDemo extends StatefulWidget {
  const ConclusionDemo({super.key});

  @override
  State<ConclusionDemo> createState() => _ConclusionDemoState();
}

class _ConclusionDemoState extends State<ConclusionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final glow = 0.24 + controller.value * 0.28;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _mint.withValues(alpha: 0.12),
                  border: Border.all(color: _mint.withValues(alpha: 0.48)),
                  boxShadow: [
                    BoxShadow(
                      color: _mint.withValues(alpha: glow),
                      blurRadius: 60,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle, color: _mint, size: 104),
              ),
              const SizedBox(height: 24),
              const Text(
                'Animation makes state visible',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Decoration + feedback + storytelling',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 300 : 330,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _blue.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(color: _blue.withValues(alpha: 0.18), blurRadius: 32),
        ],
      ),
      child: Row(
        children: [
          const Hero(tag: 'hero-profile-avatar', child: _Avatar(size: 76)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mina',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  '94m away · signal detected',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(
            compact ? Icons.chevron_right : Icons.favorite,
            color: compact ? Colors.white54 : _pink,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    this.color = _pink,
    this.icon = Icons.person,
  });

  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [color, _amber]),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 30),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.black.withValues(alpha: 0.72),
          size: size * 0.52,
        ),
      ),
    );
  }
}

class _CommandLine extends StatelessWidget {
  const _CommandLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.terminal, color: _mint, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  RadarPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * i / 3, gridPaint);
    }
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      gridPaint,
    );

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          _pink.withValues(alpha: 0),
          _pink.withValues(alpha: 0.44),
          _pink.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.08, 0.18],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, maxRadius, sweepPaint);

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i / 3) % 1;
      final radius = maxRadius * waveProgress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _pink.withValues(alpha: 1 - waveProgress);
      canvas.drawCircle(center, radius, paint);
    }

    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _pink.withValues(alpha: 0.18);
    canvas.drawCircle(center, 44, centerPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _IntroPulsePainter extends CustomPainter {
  _IntroPulsePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (int i = 0; i < 4; i++) {
      final p = (progress + i * 0.24) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = [
          _pink,
          _mint,
          _amber,
          _blue,
        ][i].withValues(alpha: (1 - p) * 0.65);
      canvas.drawCircle(center, 38 + p * (maxRadius - 40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _IntroPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AtmosphereBackground extends StatelessWidget {
  const _AtmosphereBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AtmospherePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF11151F), Color(0xFF171328), Color(0xFF0E1D24)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final linePaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.035);
    const gap = 34.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _mint.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      130,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.86),
      180,
      ringPaint..color = _pink.withValues(alpha: 0.07),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StageGrid extends StatelessWidget {
  const _StageGrid({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StageGridPainter(accent),
      child: const SizedBox.expand(),
    );
  }
}

class _StageGridPainter extends CustomPainter {
  _StageGridPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.055);
    const spacing = 28.0;
    for (double x = 18; x < size.width; x += spacing) {
      for (double y = 18; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.05, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StageGridPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Flutter Animate Demo')),
//         body: Center(
//           child: Text('Signal Detected')
//               .animate()
//               .fadeIn(duration: 10000.ms)
//               .slideY(begin: 30, end: 0)
//               .scale(begin: const Offset(10, 100)),
//         ),
//       ),
//     );
//   }
// }
