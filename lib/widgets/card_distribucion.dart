import 'package:distribucionesgp/models/transferencia_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InventoryCard extends StatelessWidget {
  final TransferenciaModel transferencia;
  const InventoryCard({super.key, required this.transferencia});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ), // Borde definido
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.pushNamed("distribucion", extra: transferencia);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [InventoryCardContent(transferencia: transferencia)],
        ),
      ),
    );
  }
}

class InventoryCardContent extends StatelessWidget {
  final TransferenciaModel transferencia;

  const InventoryCardContent({super.key, required this.transferencia});

  @override
  Widget build(BuildContext context) {
    const gpBlue = Color(0xFF00A3FF);
    const textMain = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF757575);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "ID ${transferencia.id} - ${transferencia.nombre}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                transferencia.createdAt.toIso8601String().split('T').first,
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            "TIENDA ORIGEN",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: gpBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "#${transferencia.tiendaOrigen}",
            style: const TextStyle(
              fontSize: 15,
              color: textMain,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // RichText(
          //   text: TextSpan(
          //     style: const TextStyle(fontSize: 14, color: textMain),
          //     children: [
          //       const TextSpan(text: "UPCs escaneados: "),
          //       TextSpan(
          //         text: "124",
          //         style: const TextStyle(
          //           fontWeight: FontWeight.bold,
          //           color: gpBlue,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          // Fila 4: Observaciones al final
          Text(
            transferencia.observaciones,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
