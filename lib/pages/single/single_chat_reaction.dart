import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../../common/widgets/log_view.dart';

const singleChatDefaultReaction = '👍';
const singleChatReactionCandidates = ['👍', '❤️', '😂', '👀', '🔥'];

enum SingleChatReactionSheetAction { add, remove }

class SingleChatReactionSelection {
  final String reaction;
  final SingleChatReactionSheetAction action;

  const SingleChatReactionSelection({
    required this.reaction,
    required this.action,
  });
}

String buildSingleChatReactionLabel(Map<String, int> reactionCounts) {
  if (reactionCounts.isEmpty) {
    return '更新reaction： 无';
  }

  final summary = reactionCounts.entries
      .where((entry) => entry.value > 0)
      .map((entry) => '${entry.key}(${entry.value})')
      .join('、');
  return summary.isEmpty ? '更新reaction： 无' : '更新reaction： $summary';
}

void applySingleChatReactionEvent(
  Map<String, int> reactionCounts,
  EMMessageReactionEvent event,
) {
  final authoritativeReactions = <String>{};

  if (event.reactions.isNotEmpty) {
    for (final reaction in event.reactions) {
      final key = reaction.reaction.trim();
      if (key.isEmpty) {
        continue;
      }
      authoritativeReactions.add(key);
      if (reaction.userCount > 0) {
        reactionCounts[key] = reaction.userCount;
      } else {
        reactionCounts.remove(key);
      }
    }
  }

  for (final operation in event.operations) {
    final reaction = operation.reaction.trim();
    if (reaction.isEmpty || authoritativeReactions.contains(reaction)) {
      continue;
    }
    final current = reactionCounts[reaction] ?? 0;
    if (operation.operate == ReactionOperate.Add) {
      reactionCounts[reaction] = current + 1;
    } else {
      final next = current - 1;
      if (next > 0) {
        reactionCounts[reaction] = next;
      } else {
        reactionCounts.remove(reaction);
      }
    }
  }
}

bool applySingleChatReactionOverlay(
  LogController controller,
  String messageId,
  Map<String, int> reactionCounts,
) {
  final label = buildSingleChatReactionLabel(reactionCounts);
  var applied = false;

  for (final entry in controller.entities) {
    final attachment = entry.attachment;
    if (attachment is EMMessage && attachment.msgId == messageId) {
      controller.updateEntry(
        entry,
        overlayLabel: label,
        overlayStyle: LogOverlayStyle.info,
      );
      applied = true;
    }
  }

  return applied;
}

Future<SingleChatReactionSelection?> showSingleChatReactionSheet(
  BuildContext context,
) {
  return showModalBottomSheet<SingleChatReactionSelection>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('选择一个表情，然后发送或删除。'),
                const SizedBox(height: 16),
                ...singleChatReactionCandidates.map(
                  (reaction) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SingleChatReactionOptionRow(reaction: reaction),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SingleChatReactionOptionRow extends StatelessWidget {
  final String reaction;

  const _SingleChatReactionOptionRow({required this.reaction});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(reaction, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reaction,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  SingleChatReactionSelection(
                    reaction: reaction,
                    action: SingleChatReactionSheetAction.add,
                  ),
                );
              },
              child: const Text('发送'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  SingleChatReactionSelection(
                    reaction: reaction,
                    action: SingleChatReactionSheetAction.remove,
                  ),
                );
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
