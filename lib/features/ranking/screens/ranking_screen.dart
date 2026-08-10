import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/calificacion_service.dart';

/// Ranking de conductores por rating (estilo podio Stitch).
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<RankingItem> _ranking = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _ranking = await CalificacionService.ranking();
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.gray,
        elevation: 0,
        title: const Text('Ranking de conductores', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _ranking.isEmpty
              ? const Center(
                  child: Text('Sin datos aún.', style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600)),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ranking.length,
                    itemBuilder: (_, i) {
                      final item = _ranking[i];
                      final esTop3 = i < 3;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: esTop3 ? AppColors.yellow : AppColors.line,
                            width: esTop3 ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: esTop3 ? AppColors.yellow : AppColors.gray,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: esTop3 ? AppColors.black : AppColors.textDim,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.yellowSoft,
                              backgroundImage: item.fotoUrl != null ? NetworkImage(item.fotoUrl!) : null,
                              child: item.fotoUrl == null
                                  ? const Icon(Icons.two_wheeler, size: 18, color: AppColors.black)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
                                  ),
                                  Text(
                                    '${item.viajes} viajes',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.yellow, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
