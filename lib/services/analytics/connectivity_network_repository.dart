import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_analyser/features/analytics/domain/repositories/network_repository.dart';

class ConnectivityNetworkRepository implements NetworkRepository {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
