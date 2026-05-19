import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/gamificacao/domain/level_up_state.dart';
import '../../../shared/widgets/app_section.dart';
import '../../../shared/widgets/money_field.dart';
import '../../../shared/widgets/progress_metric_card.dart';
import '../../../shared/widgets/stat_card.dart';

class VendasPage extends ConsumerStatefulWidget {
  const VendasPage({super.key});

  @override
  ConsumerState<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends ConsumerState<VendasPage> {
  late double _individualSale;
  late double _storeSale;

  @override
  void initState() {
    super.initState();
    final state = ref.read(levelUpProvider);
    _individualSale = state.dailyIndividualSale;
    _storeSale = state.dailyStoreSale;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(levelUpProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
      children: [
        Text(
          'Vendas',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AppSection(
          title: 'Lancamento diario',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  MoneyField(
                    label: 'Venda individual diaria',
                    initialValue: state.dailyIndividualSale,
                    onChanged: (value) => _individualSale = parseMoney(value),
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    label: 'Venda loja diaria',
                    initialValue: state.dailyStoreSale,
                    onChanged: (value) => _storeSale = parseMoney(value),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(levelUpProvider.notifier)
                          .updateSales(
                            dailyIndividualSale: _individualSale,
                            dailyStoreSale: _storeSale,
                          );
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Atualizar vendas'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ProgressMetricCard(
          title: 'Percentual mensal individual',
          value: state.monthlyIndividualPercent,
          subtitle: 'Comissao individual: ${state.individualCommissionRate}%',
        ),
        const SizedBox(height: 14),
        ProgressMetricCard(
          title: 'Percentual mensal loja',
          value: state.monthlyStorePercent,
          subtitle: 'Comissao loja: ${state.storeCommissionRate}%',
          color: AppTheme.secondary,
        ),
        const SizedBox(height: 14),
        StatCard(
          title: 'Comissao atualizada',
          value: money(state.estimatedCommission),
          subtitle: 'Estimativa com a projecao diaria atual',
          icon: Icons.payments_rounded,
          color: AppTheme.warning,
        ),
      ],
    );
  }
}
