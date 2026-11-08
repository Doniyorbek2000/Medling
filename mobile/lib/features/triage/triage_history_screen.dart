import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../widgets/states.dart';
import 'triage_result_screen.dart';
import 'triage_screen.dart';

class TriageHistoryScreen extends StatelessWidget {
  const TriageHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<MedLinkRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(l.triageHistory)),
      body: AsyncList<TriageHistoryItem>(
        load: repo.triageHistory,
        empty: EmptyView(
          icon: Icons.history_rounded,
          title: l.triageHistoryEmpty,
          action: FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TriageScreen()),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l.analyze),
          ),
        ),
        itemBuilder: (context, item, _) {
          final u = urgencyInfo(l, item.result.urgency);
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(u.icon, color: u.color, size: 32),
              title: Text(
                item.input,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    StatusChip(label: u.title, color: u.color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.fmt.dateTime(item.at),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TriageResultScreen(result: item.result),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
