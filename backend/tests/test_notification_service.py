from fastapi import BackgroundTasks

from app.services.notification_service import enqueue_notification


def test_empty_tokens_do_not_enqueue_task():
    tasks = BackgroundTasks()
    called = []

    enqueue_notification(tasks, lambda **_: called.append(True), tokens=[])

    assert tasks.tasks == []
    assert called == []


def test_notification_is_enqueued_and_payload_is_forwarded():
    tasks = BackgroundTasks()
    calls = []

    def sender(**payload):
        calls.append(payload)

    enqueue_notification(
        tasks,
        sender,
        tokens=["token-1"],
        group_id="group-1",
        amount=12.5,
    )

    assert len(tasks.tasks) == 1
    tasks.tasks[0].func(*tasks.tasks[0].args, **tasks.tasks[0].kwargs)
    assert calls == [
        {"tokens": ("token-1",), "group_id": "group-1", "amount": 12.5}
    ]


def test_notification_failure_is_isolated():
    tasks = BackgroundTasks()

    def sender(**_):
        raise RuntimeError("FCM unavailable")

    enqueue_notification(tasks, sender, tokens=["token-1"])
    tasks.tasks[0].func(*tasks.tasks[0].args, **tasks.tasks[0].kwargs)
