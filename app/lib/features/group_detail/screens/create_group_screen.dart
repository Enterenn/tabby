import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/l10n.dart';
import '../../home/cubit/home_cubit.dart';
import '../cubit/group_form_cubit.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupFormCubit(),
      child: const _CreateGroupView(),
    );
  }
}

class _CreateGroupView extends StatefulWidget {
  const _CreateGroupView();

  @override
  State<_CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<_CreateGroupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<GroupFormCubit>().create(_nameCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<GroupFormCubit, GroupFormState>(
      listener: (context, state) {
        if (state is GroupFormCreated) {
          context.read<HomeCubit>().loadGroups();
          context.pushReplacement('/groups/${state.groupId}/invite');
        } else if (state is GroupFormError) {
          showTabbySnack(context, context.l10nError(state.message));
        }
      },
      builder: (context, state) {
        final loading = state is GroupFormSubmitting;
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.newGroup)),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.createGroupHeadline,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.createGroupHint,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: context.l10n.groupName,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? context.l10n.requiredField
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const TabbyButtonSpinner()
                          : Text(context.l10n.createGroupSubmit),
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
