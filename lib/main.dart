import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TallyCounterApp());
}

class TallyCounterApp extends StatefulWidget {
  const TallyCounterApp({super.key});

  @override
  State<TallyCounterApp> createState() => _TallyCounterAppState();
}

class _TallyCounterAppState extends State<TallyCounterApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : _themeMode == ThemeMode.light
              ? ThemeMode.dark
              : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tally Counter',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _count = 0;
  int _step = 1;
  int? _targetGoal;
  bool _hapticsEnabled = true;
  bool _allowNegative = false;
  final List<String> _history = [];

  void _triggerHaptic() {
    if (_hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _increment() {
    setState(() {
      _count += _step;
      _logAction('+$_step');
    });
    _triggerHaptic();

    if (_targetGoal != null && _count == _targetGoal) {
      _showGoalReachedDialog();
    }
  }

  void _decrement() {
    if (!_allowNegative && _count - _step < 0) {
      if (_count > 0) {
        setState(() {
          _count = 0;
          _logAction('Reset to 0');
        });
        _triggerHaptic();
      }
      return;
    }

    setState(() {
      _count -= _step;
      _logAction('-$_step');
    });
    _triggerHaptic();
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Counter?'),
        content: const Text('Are you sure you want to reset the count to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () {
              setState(() {
                _count = 0;
                _history.clear();
              });
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _logAction(String label) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _history.insert(0, '$label (Total: $_count) at $timeStr');
    if (_history.length > 50) {
      _history.removeLast();
    }
  }

  void _showGoalReachedDialog() {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Goal Reached!'),
          ],
        ),
        content: Text('Congratulations! You have reached your goal of $_targetGoal.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  void _setGoalDialog() {
    final controller = TextEditingController(
      text: _targetGoal != null ? _targetGoal.toString() : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Target Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Target count',
            hintText: 'e.g. 100',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _targetGoal = null);
              Navigator.pop(ctx);
            },
            child: const Text('Clear Goal'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _targetGoal = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Count History',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_history.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _history.clear());
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _history.isEmpty
                  ? const Center(
                      child: Text('No counts recorded yet.'),
                    )
                  : ListView.separated(
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, index) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.history, size: 20),
                          title: Text(_history[index]),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _targetGoal != null && _targetGoal! > 0
        ? (_count / _targetGoal!).clamp(0.0, 1.0)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tally Counter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _hapticsEnabled ? Icons.vibration : Icons.phone_android_outlined,
            ),
            tooltip: _hapticsEnabled ? 'Haptics: On' : 'Haptics: Off',
            onPressed: () {
              setState(() => _hapticsEnabled = !_hapticsEnabled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _hapticsEnabled ? 'Haptic feedback enabled' : 'Haptic feedback disabled',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: _showHistoryModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Target progress indicator if goal is configured
            if (_targetGoal != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goal: $_count / $_targetGoal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${((progress ?? 0) * 100).toInt()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

            // Step Selector & Settings Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step selector chips
                  Row(
                    children: [
                      Text(
                        'Step: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [1, 5, 10].map((stepValue) {
                          final isSelected = _step == stepValue;
                          return ChoiceChip(
                            label: Text('+$stepValue'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _step = stepValue);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Goal & negative count options
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.flag_outlined,
                          color: _targetGoal != null ? colorScheme.primary : null,
                        ),
                        tooltip: 'Set Goal',
                        onPressed: _setGoalDialog,
                      ),
                      IconButton(
                        icon: Icon(
                          _allowNegative ? Icons.exposure_neg_1 : Icons.exposure_zero,
                          color: _allowNegative ? colorScheme.primary : null,
                        ),
                        tooltip: _allowNegative ? 'Allow negative: On' : 'Allow negative: Off',
                        onPressed: () {
                          setState(() => _allowNegative = !_allowNegative);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _allowNegative
                                    ? 'Negative counts allowed'
                                    : 'Negative counts prevented',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Large interactive counter display (tap to increment)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Material(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(32),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    splashColor: colorScheme.primary.withOpacity(0.2),
                    onTap: _increment,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              '$_count',
                              key: ValueKey<int>(_count),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 96,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap screen to count (+${_step})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action Buttons (Minus, Reset, Plus)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decrement Button
                  FloatingActionButton.large(
                    heroTag: 'decrement',
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    onPressed: _decrement,
                    tooltip: 'Decrease',
                    child: const Icon(Icons.remove, size: 36),
                  ),

                  // Reset Button
                  IconButton.filledTonal(
                    onPressed: _reset,
                    iconSize: 28,
                    padding: const EdgeInsets.all(16),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset Count',
                  ),

                  // Increment Button
                  FloatingActionButton.large(
                    heroTag: 'increment',
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    onPressed: _increment,
                    tooltip: 'Increase',
                    child: const Icon(Icons.add, size: 36),
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
