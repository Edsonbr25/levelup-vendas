import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/gamificacao/domain/level_up_state.dart';

class DataStatusBanner extends StatelessWidget {
  const DataStatusBanner({
    super.key,
    required this.state,
    required this.isLoading,
    required this.onRefresh,
  });

  final LevelUpState state;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(minHeight: 3),
      );
    }

    if (!state.isFallback) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppTheme.warning),
              const SizedBox(width: 12),
              Expanded(
                child: _FallbackMessage(errorMessage: state.errorMessage),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Recarregar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackMessage extends StatelessWidget {
  const _FallbackMessage({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Usando dados locais temporarios. Verifique a conexao com o Supabase.',
        ),
        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB6C2D3)),
          ),
        ],
      ],
    );
  }
}
