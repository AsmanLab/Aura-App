import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AuraHistoryTile extends StatelessWidget {
  final AuraTransaction transaction;

  const AuraHistoryTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.points > 0;
    final date = DateFormat('MMM d, yyyy').format(transaction.timestamp);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPositive ? Colors.green[100] : Colors.red[100],
        child: Icon(
          isPositive ? Icons.thumb_up : Icons.thumb_down,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction.comment,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(date),
      trailing: Text(
        '${transaction.points > 0 ? '+' : ''}${transaction.points}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green : Colors.red,
          fontSize: 16,
        ),
      ),
    );
  }
}
