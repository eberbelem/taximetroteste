import 'dart:async';
import '../core/models/trip.dart';
import 'database_service.dart';

class SyncService {
  final DatabaseService _databaseService;
  StreamSubscription<List<Trip>>? _syncSubscription;

  SyncService(this._databaseService);

  Future<void> sincronizarTripsPendentes() async {
    try {
      final tripsPendentes =
          await _databaseService.listarTripsNaoSincronizados();

      for (final trip in tripsPendentes) {
        try {
          await _enviarParaNuvem(trip);
          await _databaseService.marcarSincronizado(trip.id);
        } catch (e) {
          // Falha na sincronização — será retentada na próxima vez
        }
      }
    } catch (e) {
      // Sem conexão ou erro de banco
    }
  }

  Future<void> _enviarParaNuvem(Trip trip) async {
    // TODO: Implementar envio para Firebase/Firestore ou Supabase
    //
    // Exemplo com Firebase:
    // final firestore = FirebaseFirestore.instance;
    // await firestore.collection('trips').doc(trip.id).set(trip.toMap());
    //
    // Exemplo com Supabase:
    // final supabase = SupabaseClient(url, anonKey);
    // await supabase.from('trips').upsert(trip.toMap());
  }

  void iniciarSincronizacaoPeriodica() {
    Timer.periodic(const Duration(minutes: 1), (_) {
      sincronizarTripsPendentes();
    });
  }

  void dispose() {
    _syncSubscription?.cancel();
  }
}
