import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';

sealed class GroupFormState extends Equatable {
  const GroupFormState();
  @override
  List<Object?> get props => [];
}

class GroupFormIdle extends GroupFormState {
  const GroupFormIdle();
}

class GroupFormSubmitting extends GroupFormState {
  const GroupFormSubmitting();
}

class GroupFormCreated extends GroupFormState {
  const GroupFormCreated(this.groupId);
  final String groupId;
  @override
  List<Object?> get props => [groupId];
}

class GroupFormJoined extends GroupFormState {
  const GroupFormJoined();
}

class GroupFormError extends GroupFormState {
  const GroupFormError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class GroupFormCubit extends Cubit<GroupFormState> {
  GroupFormCubit({GroupsRepository? groups})
      : _groups = groups ?? groupsRepository,
        super(const GroupFormIdle());

  final GroupsRepository _groups;

  Future<void> create(String name) async {
    emit(const GroupFormSubmitting());
    try {
      final group = await _groups.create(name);
      if (!isClosed) emit(GroupFormCreated(group.id));
    } catch (e) {
      if (!isClosed) emit(GroupFormError(ApiFailure.from(e).message));
    }
  }

  Future<void> join(String code) async {
    emit(const GroupFormSubmitting());
    try {
      await _groups.join(code);
      if (!isClosed) emit(const GroupFormJoined());
    } catch (e) {
      if (!isClosed) emit(GroupFormError(ApiFailure.from(e).message));
    }
  }
}

sealed class InviteState extends Equatable {
  const InviteState();
  @override
  List<Object?> get props => [];
}

class InviteLoading extends InviteState {
  const InviteLoading();
}

class InviteReady extends InviteState {
  const InviteReady(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

class InviteError extends InviteState {
  const InviteError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class InviteCubit extends Cubit<InviteState> {
  InviteCubit(this._groupId, {GroupsRepository? groups})
      : _groups = groups ?? groupsRepository,
        super(const InviteLoading());

  final String _groupId;
  final GroupsRepository _groups;

  Future<void> generate() async {
    emit(const InviteLoading());
    try {
      final code = await _groups.createInvite(_groupId);
      if (!isClosed) emit(InviteReady(code));
    } catch (e) {
      if (!isClosed) emit(InviteError(ApiFailure.from(e).message));
    }
  }
}
