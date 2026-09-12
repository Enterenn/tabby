import uuid

from app.core.deps import can_manage_paid_record, is_group_admin

ADMIN = uuid.UUID("11111111-1111-1111-1111-111111111111")
MEMBER = uuid.UUID("22222222-2222-2222-2222-222222222222")
PAYER = uuid.UUID("33333333-3333-3333-3333-333333333333")


def test_creator_is_admin():
    assert is_group_admin(ADMIN, ADMIN)
    assert not is_group_admin(MEMBER, ADMIN)


def test_payer_can_manage_own_record():
    assert can_manage_paid_record(PAYER, ADMIN, PAYER)


def test_admin_can_manage_any_record():
    assert can_manage_paid_record(ADMIN, ADMIN, PAYER)


def test_other_member_cannot_manage_record():
    assert not can_manage_paid_record(MEMBER, ADMIN, PAYER)
