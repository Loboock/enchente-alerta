import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import 'alertas_service.dart';
import 'auth_service.dart';
import 'enderecos_service.dart';
import 'localizacao_service.dart';
import 'perigos_service.dart';

// Filtro dos alertas por localização (RF08).
//
// Alerta sem área de risco vale para a cidade toda. Alerta ligado a áreas
// só aparece para quem está a até `raioKm` de uma delas, contando a partir
// do endereço padrão (ou da posição atual, se não houver endereço). A
// Defesa Civil vê todos.

/// Ponto de referência do usuário: endereço padrão ou posição atual.
LatLng? pontoDeReferencia() =>
    EnderecosService.instance.padrao?.localizacao ??
    LocalizacaoService.instance.posicao.value?.ponto;

/// Raio escolhido em Perfil (padrão 2 km).
double raioDosAlertasKm() =>
    AuthService.instance.usuario?.preferenciaNotificacao?.raioKm ?? 2;

/// Alertas ativos que valem para quem está usando o app agora.
List<Alerta> alertasParaMim([DateTime? agora]) {
  final ativos = AlertasService.instance.ativos(agora);
  if (AuthService.instance.usuario?.ehDefesaCivil ?? false) return ativos;
  final areas = {for (final a in PerigosService.instance.areas) a.id: a};
  final ponto = pontoDeReferencia();
  final raio = raioDosAlertasKm();
  return [
    for (final a in ativos)
      if (alertaValePara(a, ponto: ponto, raioKm: raio, areas: areas)) a,
  ];
}

/// Regra do filtro, separada para ser testada.
bool alertaValePara(
  Alerta alerta, {
  required LatLng? ponto,
  required double raioKm,
  required Map<String, AreaRisco> areas,
}) {
  if (alerta.areasRiscoIds.isEmpty) return true; // cidade toda
  // Sem saber onde a pessoa está, é mais seguro mostrar.
  if (ponto == null) return true;
  final conhecidas = [
    for (final id in alerta.areasRiscoIds) ?areas[id],
  ];
  // Áreas excluídas depois do alerta: mostra para não esconder o aviso.
  if (conhecidas.isEmpty) return true;
  return conhecidas.any((a) => distanciaAteAreaKm(ponto, a) <= raioKm);
}

/// Distância em km do ponto até a borda da área (0 se estiver dentro).
double distanciaAteAreaKm(LatLng p, AreaRisco area) {
  if (area.poligono.isEmpty) return double.infinity;
  if (area.poligono.length >= 3 && area.contem(p)) return 0;
  // Projeção plana em volta do ponto: boa o bastante para alguns km.
  const kmPorGrau = 111.32;
  final cosLat = math.cos(p.latitude * math.pi / 180);
  (double, double) xy(LatLng q) => (
        (q.longitude - p.longitude) * kmPorGrau * cosLat,
        (q.latitude - p.latitude) * kmPorGrau,
      );
  var menor = double.infinity;
  final pts = area.poligono;
  for (var i = 0; i < pts.length; i++) {
    final (ax, ay) = xy(pts[i]);
    final (bx, by) = xy(pts[(i + 1) % pts.length]);
    final dx = bx - ax, dy = by - ay;
    final comp = dx * dx + dy * dy;
    final t = comp == 0 ? 0.0 : ((-ax * dx - ay * dy) / comp).clamp(0.0, 1.0);
    final cx = ax + t * dx, cy = ay + t * dy;
    menor = math.min(menor, math.sqrt(cx * cx + cy * cy));
  }
  return menor;
}
