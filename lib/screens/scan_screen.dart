import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'add_ingredients_screen.dart';

/// Placeholder for now. Step 2 of the build adds the real camera
/// (image_picker) and ingredient recognition.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SheetLayout(
      headerHeight: 64,
      header: Row(children: [const CircleBack(), const SizedBox(width: 12), Text('Scan Ingredients', style: heading(24, color: W2T.butter))]),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: W2T.rust, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera_outlined, color: W2T.butter, size: 52),
            ),
            const SizedBox(height: 24),
            Text('Camera scanning is coming soon', textAlign: TextAlign.center, style: heading(22)),
            const SizedBox(height: 8),
            const Text('For now, add what you have from the list.', textAlign: TextAlign.center, style: TextStyle(color: W2T.muted)),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddIngredientsScreen())),
              child: const Text('Type ingredients instead'),
            ),
          ],
        ),
      ),
    );
  }
}
