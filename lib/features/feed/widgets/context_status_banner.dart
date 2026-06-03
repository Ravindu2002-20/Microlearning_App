import 'package:flutter/material.dart';


import '../../../../core/services/context_engine_service.dart';

class ContextStatusBanner extends StatelessWidget {
  final UserContextState contextState;

  const ContextStatusBanner({super.key, required this.contextState});

  @override
  Widget build(BuildContext context) {
    final networkColor = switch (contextState.networkStrength) {
      AppNetworkStrength.weak => Colors.red,
      AppNetworkStrength.medium => Colors.orange,
      AppNetworkStrength.strong => Colors.green,
    };

    final networkIcon = switch (contextState.networkStrength) {
      AppNetworkStrength.weak => Icons.signal_wifi_0_bar,
      AppNetworkStrength.medium => Icons.network_cell,
      AppNetworkStrength.strong => Icons.wifi,
    };

    final motionIcon = contextState.isInMotion
        ? Icons.directions_walk
        : Icons.self_improvement;

    final motionColor = contextState.isInMotion ? Colors.amber : Colors.green;
    final motionLabel = contextState.isInMotion ? 'Moving' : 'Stationary';

    final networkLabel = switch (contextState.networkStrength) {
      AppNetworkStrength.weak => 'Weak Signal',
      AppNetworkStrength.medium => 'Medium Signal',
      AppNetworkStrength.strong => 'Strong Signal',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(motionIcon, size: 18, color: motionColor),
              const SizedBox(width: 6),
              Text(
                motionLabel,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Icon(networkIcon, size: 18, color: networkColor),
              const SizedBox(width: 6),
              Text(
                networkLabel,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

