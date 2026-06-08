import 'package:aura_app/features/auth/presentation/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_app/features/roulette/data/roulette_service.dart';
import 'package:aura_app/core/widgets/roulette_wheel.dart';

class RouletteScreen extends ConsumerStatefulWidget {
  const RouletteScreen({super.key});

  @override
  ConsumerState<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends ConsumerState<RouletteScreen>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _resultController;
  bool _isSpinning = false;
  int? _result;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSpin = ref.watch(canSpinRouletteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura Roulette'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.casino,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Daily Aura Roulette',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spin once per day for bonus aura points!\n70% chance for -10, 30% chance for +5',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Roulette Wheel
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RouletteWheel(
                      controller: _wheelController,
                      isSpinning: _isSpinning,
                    ),

                    const SizedBox(height: 32),

                    // Result Display
                    if (_result != null)
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _resultController,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: _result! > 0 ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _result! > 0
                                ? '+$_result Aura Points!'
                                : '$_result Aura Points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Spin Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: canSpin.when(
                data: (canSpin) => ElevatedButton(
                  onPressed: (canSpin && !_isSpinning) ? _spinRoulette : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSpinning
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Spinning...'),
                          ],
                        )
                      : Text(
                          canSpin ? 'SPIN THE WHEEL' : 'Come back tomorrow!',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                loading: () => const ElevatedButton(
                  onPressed: null,
                  child: Text('Loading...'),
                ),
                error: (_, __) => ElevatedButton(
                  onPressed: () => ref.invalidate(canSpinRouletteProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _spinRoulette() async {
    setState(() {
      _isSpinning = true;
      _result = null;
    });

    try {
      // Start wheel animation
      await _wheelController.forward();

      // Perform the actual spin
      final spin = await ref.read(rouletteServiceProvider).spinRoulette();

      setState(() {
        _result = spin.result;
      });

      // Show result animation
      await _resultController.forward();

      // Refresh providers
      ref.invalidate(canSpinRouletteProvider);
      ref.invalidate(currentUserProvider);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              spin.result > 0
                  ? 'Congratulations! You earned ${spin.result} aura points!'
                  : 'Better luck tomorrow! You lost ${spin.result.abs()} aura points.',
            ),
            backgroundColor: spin.result > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isSpinning = false;
      });
    }
  }
}
