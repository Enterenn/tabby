import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';
import '../../home/cubit/home_cubit.dart';
import '../cubit/group_form_cubit.dart';

class JoinGroupScreen extends StatelessWidget {
  const JoinGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupFormCubit(),
      child: const _JoinGroupView(),
    );
  }
}

class _JoinGroupView extends StatefulWidget {
  const _JoinGroupView();

  @override
  State<_JoinGroupView> createState() => _JoinGroupViewState();
}

class _JoinGroupViewState extends State<_JoinGroupView> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<GroupFormCubit>().join(_codeCtrl.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<GroupFormCubit, GroupFormState>(
      listener: (context, state) {
        if (state is GroupFormJoined) {
          context.read<HomeCubit>().loadGroups();
          showTabbySnack(context, context.l10n.joinedGroup);
          context.go('/home');
        } else if (state is GroupFormError) {
          showTabbySnack(context, context.l10nError(state.message));
        }
      },
      builder: (context, state) {
        final loading = state is GroupFormSubmitting;
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.joinGroup)),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.joinGroupHeadline,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.joinGroupHint,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 8,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: context.tabbyType.clockDisplay.copyWith(
                      fontSize: 36,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.inviteCodeLabel,
                      counterText: '',
                    ),
                    validator: (v) => v == null || v.trim().length != 8
                        ? context.l10n.inviteCodeRequired
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const TabbyButtonSpinner()
                          : Text(context.l10n.joinSubmit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
