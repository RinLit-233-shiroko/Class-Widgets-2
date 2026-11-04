import sentry_sdk

sentry_sdk.init(
    dsn="https://06e0f03556cfa914d16564d4bebba0e7@o4512074415603712.ingest.us.sentry.io/4512074431332352",
    # To customize collected data (user info, request bodies, AI inputs/outputs),
    # see https://docs.sentry.io/platforms/python/data-management/data-collected/
    # data_collection={"user_info": False},
)

division_by_zero = 1 / 0