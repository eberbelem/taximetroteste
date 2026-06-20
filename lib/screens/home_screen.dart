import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/models/fare_table.dart';
import '../core/models/trip.dart';
import '../core/taximeter_algorithm.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/background_service.dart';
import '../widgets/fare_display.dart';
import '../widgets/info_panel.dart';
import '../widgets/control_button.dart';
import '../widgets/destination_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _valorAtual = 0.0;
  double _distanciaAtual = 0.0;
  int _fracoes = 0;
  String _tempoAtual = '00:00:00';
  TripStatus _status = TripStatus.aguardando;
  int _tarifaSelecionada = 1;
  StreamSubscription<TripPoint>? _locationSub;

  String _nomeMotorista = '';
  String _placa = 'ABC-1234';
  String _carro = 'Toyota Corolla';
  String? _localEmbarque;
  DateTime? _horaEmbarque;
  String? _localDesembarque;
  DateTime? _horaDesembarque;
  TripPoint? _ultimoPonto;

  int _tarifaPorHorario() {
    final h = DateTime.now().hour;
    return (h >= 7 && h < 20) ? 1 : 2;
  }

  @override
  void initState() {
    super.initState();
    _tarifaSelecionada = _tarifaPorHorario();
    _initListeners();
  }

  void _initListeners() {
    final taximeter = context.read<TaximeterAlgorithm>();
    taximeter.onValorAtualizado
        .listen((v) => mounted ? setState(() => _valorAtual = v) : null);
    taximeter.onDistanciaAtualizada
        .listen((d) => mounted ? setState(() => _distanciaAtual = d) : null);
    taximeter.onFracaoAtualizada
        .listen((n) => mounted ? setState(() => _fracoes = n) : null);
    taximeter.onTempoAtualizado.listen((t) {
      if (!mounted) return;
      setState(() {
        final h = t.inHours.toString().padLeft(2, '0');
        final m = t.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = t.inSeconds.remainder(60).toString().padLeft(2, '0');
        _tempoAtual = '$h:$m:$s';
      });
    });
    taximeter.onStatusChanged.listen((s) {
      if (!mounted) return;
      setState(() => _status = s);
    });
  }

  Future<void> _iniciarCorrida() async {
    final locationService = context.read<LocationService>();
    final taximeter = context.read<TaximeterAlgorithm>();
    final databaseService = context.read<DatabaseService>();

    final gpsOk = await locationService.isGpsHabilitado();
    if (!gpsOk && mounted) {
      _mostrarAlerta('LIGUE O GPS',
          'O GPS está desabilitado. Ative a localização para iniciar a corrida.');
      return;
    }

    await BackgroundService.iniciar();
    await locationService.iniciarMonitoramento();
    taximeter.iniciarCorrida(tarifaInicial: _tarifaSelecionada);

    _horaEmbarque = DateTime.now();
    _localEmbarque = null;
    _localDesembarque = null;
    _horaDesembarque = null;
    _ultimoPonto = null;

    _locationSub = locationService.locationStream?.listen((ponto) {
      taximeter.processarNovoPontoGPS(
        latitude: ponto.latitude,
        longitude: ponto.longitude,
        velocidade: ponto.velocidade,
        timestamp: ponto.timestamp,
        acelerometroMagnitude: locationService.magnitudeAcelerometro,
      );
      if (_localEmbarque == null) {
        _localEmbarque =
            '${ponto.latitude.toStringAsFixed(5)}, ${ponto.longitude.toStringAsFixed(5)}';
      }
      _ultimoPonto = ponto;
    });

    await databaseService.salvarTrip(taximeter.tripAtual!);
  }

  Future<void> _encerrarCorrida() async {
    final taximeter = context.read<TaximeterAlgorithm>();
    final locationService = context.read<LocationService>();
    final databaseService = context.read<DatabaseService>();

    taximeter.encerrarCorrida();
    _locationSub?.cancel();
    locationService.pararMonitoramento();
    await BackgroundService.parar();
    await databaseService.atualizarTrip(taximeter.tripAtual!);

    _horaDesembarque = DateTime.now();
    if (_ultimoPonto != null) {
      _localDesembarque =
          '${_ultimoPonto!.latitude.toStringAsFixed(5)}, ${_ultimoPonto!.longitude.toStringAsFixed(5)}';
    }
  }

  void _mostrarAlerta(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(titulo,
            style: const TextStyle(color: AppColors.statusOrange)),
        content: Text(mensagem,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK',
                style: TextStyle(color: AppColors.farePrimary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taximeter = context.read<TaximeterAlgorithm>();
    final ft = taximeter.fareTable;
    final isRunning = _status == TripStatus.emAndamento;
    final tarifa = isRunning
        ? taximeter.tripAtual?.tarifaAtiva ?? 1
        : _tarifaSelecionada;

    final showTotal = _status == TripStatus.encerrada && _valorAtual > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(ft),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: DestinationBar(
                currentLat: null,
                currentLon: null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        const Spacer(flex: 1),
                        FareDisplay(
                          valor: _valorAtual,
                          isRunning: isRunning,
                          showTotalLabel: showTotal,
                        ),
                        const Spacer(flex: 1),
                        InfoPanel(
                          tempo: _tempoAtual,
                          distanciaKm: _distanciaAtual / 1000.0,
                          fracoes: _fracoes,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusBar(isRunning, tarifa, showTotal),
                        const Spacer(flex: 2),
                      ],
                    );
                  },
                ),
              ),
            ),
            _buildBottomBar(isRunning, tarifa, showTotal),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(FareTable ft) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(Icons.local_taxi_rounded,
                size: 22, color: AppColors.statusGold),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TAXÍMETRO DIGITAL',
                  style: AppTypography.tabHeader
                      .copyWith(color: AppColors.textSecondary)),
              Text('v1.0 · Inmetro nº 201/2002',
                  style: AppTypography.tariffSub
                      .copyWith(color: AppColors.textDim)),
            ],
          ),
          const Spacer(),
          _buildSignalIndicator(),
          const SizedBox(width: 8),
          _buildDriverButton(),
          const SizedBox(width: 6),
          _buildHistoryButton(),
        ],
      ),
    );
  }

  Widget _buildSignalIndicator() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(Icons.gps_fixed, size: 16, color: AppColors.farePrimary),
    );
  }

  Widget _buildHistoryButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarHistorico(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(Icons.history_rounded,
              size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDriverButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _configurarMotorista,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(
            _nomeMotorista.isEmpty
                ? Icons.person_outline_rounded
                : Icons.person_rounded,
            size: 20,
            color: _nomeMotorista.isEmpty
                ? AppColors.textSecondary
                : AppColors.farePrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isRunning, int tarifa, bool showTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning
                  ? AppColors.farePrimary
                  : showTotal
                      ? AppColors.statusGold
                      : AppColors.textDim,
              boxShadow: isRunning
                  ? [
                      BoxShadow(
                        color: AppColors.farePrimary.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isRunning
                ? 'CORRIDA EM ANDAMENTO'
                : showTotal
                    ? 'CORRIDA ENCERRADA'
                    : 'AGUARDANDO CORRIDA',
            style: AppTypography.tariffSub.copyWith(
              color: isRunning
                  ? AppColors.farePrimary
                  : showTotal
                      ? AppColors.statusGold
                      : AppColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (isRunning)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tarifa == 1
                    ? AppColors.tariff1.withValues(alpha: 0.15)
                    : AppColors.tariff2.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'B$tarifa',
                style: AppTypography.tariffSub.copyWith(
                  color:
                      tarifa == 1 ? AppColors.tariff1 : AppColors.tariff2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isRunning, int tarifa, bool showTotal) {
    final taximeter = context.read<TaximeterAlgorithm>();
    final corTarifa = tarifa == 1 ? AppColors.tariff1 : AppColors.tariff2;

    if (showTotal) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ControlButton(
                isRunning: isRunning,
                onPressed: _iniciarCorrida,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _mostrarRecibo,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 18, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'RECIBO',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ControlButton(
              isRunning: isRunning,
              onPressed: isRunning ? _encerrarCorrida : _iniciarCorrida,
            ),
          ),
          if (!showTotal) const SizedBox(width: 10),
          if (!showTotal)
            GestureDetector(
              onTap: () {
                if (isRunning) {
                  taximeter.alternarTarifa(tarifa: tarifa == 1 ? 2 : 1);
                  setState(() {});
                } else {
                  setState(() => _tarifaSelecionada = tarifa == 1 ? 2 : 1);
                }
              },
              child: Container(
                constraints: const BoxConstraints(minWidth: 120),
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: corTarifa.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: corTarifa.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BANDEIRA $tarifa',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: corTarifa,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '⇄',
                      style: TextStyle(
                        fontSize: 12,
                        color: corTarifa.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarRecibo() {
    showDialog(
      context: context,
      builder: (_) => _ReciboDialog(
        valor: _valorAtual,
        distanciaKm: _distanciaAtual / 1000.0,
        fracoes: _fracoes,
        tempo: _tempoAtual,
        bandeira: _tarifaSelecionada,
        nomeMotorista: _nomeMotorista,
        placa: _placa,
        carro: _carro,
        localEmbarque: _localEmbarque,
        horaEmbarque: _horaEmbarque,
        localDesembarque: _localDesembarque,
        horaDesembarque: _horaDesembarque,
      ),
    );
  }

  void _configurarMotorista() {
    final controller = TextEditingController(text: _nomeMotorista);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('NOME DO MOTORISTA',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Digite seu nome',
            hintStyle: TextStyle(color: AppColors.textDim),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.farePrimary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _nomeMotorista = controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('SALVAR',
                style: TextStyle(color: AppColors.farePrimary)),
          ),
        ],
      ),
    );
  }

  void _mostrarHistorico(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const _HistoricoScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _ReciboDialog extends StatelessWidget {
  final double valor;
  final double distanciaKm;
  final int fracoes;
  final String tempo;
  final int bandeira;
  final String nomeMotorista;
  final String placa;
  final String carro;
  final String? localEmbarque;
  final DateTime? horaEmbarque;
  final String? localDesembarque;
  final DateTime? horaDesembarque;

  const _ReciboDialog({
    required this.valor,
    required this.distanciaKm,
    required this.fracoes,
    required this.tempo,
    required this.bandeira,
    required this.nomeMotorista,
    required this.placa,
    required this.carro,
    this.localEmbarque,
    this.horaEmbarque,
    this.localDesembarque,
    this.horaDesembarque,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  size: 24, color: AppColors.statusGold),
            ),
            const SizedBox(height: 12),
            Text('RECIBO DE CORRIDA',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('TAXÍMETRO DIGITAL · Inmetro nº 201/2002',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.3)),
            const SizedBox(height: 20),
            _linha('VALOR', 'R\$ ${valor.toStringAsFixed(2)}',
                AppColors.farePrimary, true),
            const SizedBox(height: 16),
            // Driver info
            if (nomeMotorista.isNotEmpty)
              _grupo('MOTORISTA', [
                _linhaSimples(nomeMotorista),
                _linhaSimples('$carro · $placa'),
              ]),
            if (nomeMotorista.isEmpty)
              _grupo('VEÍCULO', [
                _linhaSimples('$carro · $placa'),
              ]),
            const SizedBox(height: 12),
            // Trip info
            _grupo('VIAGEM', [
              _linha('Bandeira', bandeira == 1 ? 'BANDEIRA 1' : 'BANDEIRA 2'),
              _linha('Distância', '${distanciaKm.toStringAsFixed(2)} km'),
              _linha('Frações', fracoes.toString()),
              _linha('Tempo', tempo),
            ]),
            const SizedBox(height: 12),
            // Boarding / Disembarkation
            _grupo('EMBARQUE', [
              _linha('Horário', _fmt(horaEmbarque)),
              if (localEmbarque != null) _linha('Local', localEmbarque!),
            ]),
            const SizedBox(height: 8),
            _grupo('DESEMBARQUE', [
              _linha('Horário', _fmt(horaDesembarque)),
              if (localDesembarque != null)
                _linha('Local', localDesembarque!),
            ]),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _botaoAcao(
                    icon: Icons.print_rounded,
                    label: 'IMPRIMIR',
                    cor: AppColors.textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      _imprimir(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _botaoAcao(
                    icon: Icons.chat_rounded,
                    label: 'WHATSAPP',
                    cor: const Color(0xFF25D366),
                    onTap: () {
                      Navigator.pop(context);
                      _pedirNumeroWhatsApp(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                child: const Text('FECHAR',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppColors.textTertiary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoAcao({
    required IconData icon,
    required String label,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: cor),
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: cor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }

  void _imprimir(BuildContext context) async {
    final pdf = await _gerarPdf();
    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'recibo_corrida.pdf',
    );
  }

  Future< pw.Document> _gerarPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('RECIBO DE CORRIDA',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('TAXÍMETRO DIGITAL · Inmetro nº 201/2002',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: const PdfColor.fromInt(0xFF888888))),
                pw.SizedBox(height: 20),
                pw.Text('R\$ ${valor.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF39FF14))),
                pw.SizedBox(height: 24),
                _grupoPdf('MOTORISTA', [
                  if (nomeMotorista.isNotEmpty) nomeMotorista,
                  '$carro · $placa',
                ]),
                pw.SizedBox(height: 12),
                _grupoPdf('VIAGEM', [
                  'Bandeira: ${bandeira == 1 ? "BANDEIRA 1" : "BANDEIRA 2"}',
                  'Distância: ${distanciaKm.toStringAsFixed(2)} km',
                  'Frações: $fracoes',
                  'Tempo: $tempo',
                ]),
                pw.SizedBox(height: 12),
                _grupoPdf('EMBARQUE', [
                  'Horário: ${_fmt(horaEmbarque)}',
                  if (localEmbarque != null) 'Local: $localEmbarque',
                ]),
                pw.SizedBox(height: 8),
                _grupoPdf('DESEMBARQUE', [
                  'Horário: ${_fmt(horaDesembarque)}',
                  if (localDesembarque != null)
                    'Local: $localDesembarque',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _grupoPdf(String titulo, List<String> linhas) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.w600,
                color: PdfColor.fromInt(0xFFFFD700))),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1A1A1A),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: linhas
                .map((l) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 1),
                      child: pw.Text(l,
                          style: const pw.TextStyle(fontSize: 11)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _pedirNumeroWhatsApp(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('WHATSAPP',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Número do cliente:',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: const InputDecoration(
                hintText: '55 11 99999-9999',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.farePrimary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _enviarWhatsApp(context, controller.text.trim());
            },
            child: const Text('ENVIAR',
                style: TextStyle(color: AppColors.farePrimary)),
          ),
        ],
      ),
    );
  }

  void _enviarWhatsApp(BuildContext context, String numero) async {
    final texto = _textoRecibo();
    final uri = Uri.parse(
      'https://wa.me/${numero.replaceAll(RegExp(r'[^\d]'), '')}'
      '?text=${Uri.encodeComponent(texto)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _mostrarAlerta(context, 'ERRO',
          'Não foi possível abrir o WhatsApp. Verifique se o app está instalado.');
    }
  }

  void _mostrarAlerta(BuildContext context, String titulo, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(titulo,
            style:
                const TextStyle(color: AppColors.statusOrange, fontSize: 16)),
        content: Text(msg,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('OK',
                style: TextStyle(color: AppColors.farePrimary)),
          ),
        ],
      ),
    );
  }

  String _textoRecibo() {
    final buf = StringBuffer();
    buf.writeln('🧾 *RECIBO DE CORRIDA*');
    buf.writeln('TAXÍMETRO DIGITAL · Inmetro nº 201/2002');
    buf.writeln('');
    buf.writeln('*VALOR:* R\$ ${valor.toStringAsFixed(2)}');
    buf.writeln('');
    if (nomeMotorista.isNotEmpty) {
      buf.writeln('*MOTORISTA*');
      buf.writeln(nomeMotorista);
    }
    buf.writeln('$carro · $placa');
    buf.writeln('');
    buf.writeln('*VIAGEM*');
    buf.writeln(
        'Bandeira: ${bandeira == 1 ? "BANDEIRA 1" : "BANDEIRA 2"}');
    buf.writeln('Distância: ${distanciaKm.toStringAsFixed(2)} km');
    buf.writeln('Frações: $fracoes');
    buf.writeln('Tempo: $tempo');
    buf.writeln('');
    buf.writeln('*EMBARQUE*');
    buf.writeln('Horário: ${_fmt(horaEmbarque)}');
    if (localEmbarque != null) buf.writeln('Local: $localEmbarque');
    buf.writeln('');
    buf.writeln('*DESEMBARQUE*');
    buf.writeln('Horário: ${_fmt(horaDesembarque)}');
    if (localDesembarque != null) {
      buf.writeln('Local: $localDesembarque');
    }
    return buf.toString();
  }

  Widget _grupo(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: AppColors.statusGold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _linha(String label, String valor, [Color? cor, bool grande = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: grande ? 13 : 12,
                  color: AppColors.textTertiary)),
          Text(valor,
              style: TextStyle(
                fontSize: grande ? 22 : 13,
                fontWeight: grande ? FontWeight.w700 : FontWeight.w500,
                color: cor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _linhaSimples(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(texto,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textPrimary)),
    );
  }
}

class _HistoricoScreen extends StatelessWidget {
  const _HistoricoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('HISTÓRICO DE CORRIDAS',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppColors.textSecondary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: FutureBuilder(
        future: context.read<DatabaseService>().listarTodasTrips(limit: 50),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 48, color: AppColors.textDim),
                  const SizedBox(height: 16),
                  const Text('NENHUMA CORRIDA ENCONTRADA',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5)),
                ],
              ),
            );
          }
          final trips = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final trip = trips[index];
              final encerrada = trip.status == TripStatus.encerrada;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: encerrada
                            ? AppColors.farePrimary.withValues(alpha: 0.1)
                            : AppColors.statusOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        encerrada
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: encerrada
                            ? AppColors.farePrimary
                            : AppColors.statusOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.formatarValor(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(trip.distanciaTotalMetros / 1000).toStringAsFixed(2)} km · '
                            '${trip.nf} frações',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            trip.inicio.toString().substring(0, 19),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (encerrada)
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: AppColors.textDim),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
