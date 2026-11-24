import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../bloc/breeds_bloc.dart';
import '../bloc/breeds_state.dart';

/// Home directory screen (UI implementation expanded in Fase 5).
class BreedsListPage extends StatelessWidget {
  const BreedsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cat Directory')),
      body: BlocBuilder<BreedsBloc, BreedsState>(
        builder: (context, state) {
          return Center(
            child: Text('Razas cargadas: ${state.breeds.length}'),
          );
        },
      ),
    );
  }
}
