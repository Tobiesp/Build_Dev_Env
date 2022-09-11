FROM redmine

COPY --chown=redmine:redmine config.ru config.ru
