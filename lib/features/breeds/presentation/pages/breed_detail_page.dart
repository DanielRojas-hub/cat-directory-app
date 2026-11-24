import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../bloc/breed_detail_cubit.dart';
import '../bloc/breed_detail_state.dart';

/// Parameterized breed detail screen (`/breed/:name`) expanded in Fase 5.
class BreedDetailPage extends StatelessWidget {
  const BreedDetailPage({
    super.key,
    required this.breedName,
  });

  final String breedName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(breedName)),
      body: BlocBuilder<BreedDetailCubit, BreedDetailState>(
        builder: (context, state) {
          return Center(
            child: Text(state.breed?.breed ?? breedName),
          );
        },
      ),
    );
  }
}
