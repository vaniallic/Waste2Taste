import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Step-by-step cooking with a built-in timer.
class CookModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  int _step = 0;
  Timer? _timer;
  int? _remaining; // seconds left on the running timer

  List<RecipeStep> get _steps => widget.recipe.steps;

  void _go(int step) {
    _timer?.cancel();
    setState(() {
      _step = step;
      _remaining = null;
    });
  }

  void _toggleTimer() {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
      setState(() {});
      return;
    }
    _remaining ??= _steps[_step].timerSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining ?? 0) - 1);
      if ((_remaining ?? 0) <= 0) {
        t.cancel();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Time's up!")));
      }
    });
    setState(() {});
  }

  void _finish() {
    final messenger = ScaffoldMessenger.of(context);
    context.read<AppState>().markCooked(widget.recipe);
    Navigator.of(context).popUntil((r) => r.isFirst);
    messenger.showSnackBar(SnackBar(content: Text('${widget.recipe.name} added to your history.')));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final last = _step == _steps.length - 1;
    final running = _timer?.isActive ?? false;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: W2T.rust,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 8, 24, 0),
            child: Row(children: [
              Material(
                color: W2T.butter,
                shape: const CircleBorder(),
                child: IconButton(tooltip: 'Exit', icon: const Icon(Icons.close_rounded, color: W2T.rustDark), onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.recipe.name, style: const TextStyle(color: W2T.butter, fontWeight: FontWeight.w600, fontSize: 15))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
            child: Row(children: [
              for (var i = 0; i < _steps.length; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == _steps.length - 1 ? 0 : 6),
                    height: 6,
                    decoration: BoxDecoration(color: i <= _step ? W2T.butter : const Color(0xFFC46A4E), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 30, 24, 24 + MediaQuery.paddingOf(context).bottom),
              decoration: const BoxDecoration(color: W2T.butter, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step ${_step + 1} of ${_steps.length}', style: const TextStyle(color: W2T.rust, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Text(step.text, style: heading(26)),
                  if (step.timerSeconds != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                      decoration: BoxDecoration(color: W2T.olive, borderRadius: BorderRadius.circular(24)),
                      child: Row(children: [
                        const Icon(Icons.timer_outlined, color: W2T.butter),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_fmt(_remaining ?? step.timerSeconds!), style: heading(32, color: W2T.butter))),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: W2T.butter, foregroundColor: W2T.olive, minimumSize: const Size(96, 44)),
                          onPressed: _toggleTimer,
                          child: Text(running ? 'Pause' : 'Start'),
                        ),
                      ]),
                    ),
                  ],
                  const Spacer(),
                  Row(children: [
                    OutlinedButton(
                      onPressed: _step == 0 ? null : () => _go(_step - 1),
                      style: OutlinedButton.styleFrom(
                        shape: const CircleBorder(),
                        side: const BorderSide(color: W2T.olive, width: 2),
                        minimumSize: const Size(56, 56),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: W2T.olive),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: last ? W2T.olive : W2T.rust, foregroundColor: last ? W2T.butter : Colors.white, minimumSize: const Size.fromHeight(56)),
                        onPressed: last ? _finish : () => _go(_step + 1),
                        child: Text(last ? 'Done — mark as cooked' : 'Next step'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
