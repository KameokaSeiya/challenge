from typing import Any, Optional, Sequence

from django.apps.config import AppConfig
from django.contrib.admin.options import BaseModelAdmin
from django.core.checks.messages import CheckMessage, Error

def check_admin_app(app_configs: Optional[Sequence[AppConfig]], **kwargs: Any) -> Sequence[CheckMessage]: ...
def check_dependencies(**kwargs: Any) -> Sequence[CheckMessage]: ...

class BaseModelAdminChecks:
    def check(self, admin_obj: BaseModelAdmin, **kwargs: Any) -> Sequence[CheckMessage]: ...

class ModelAdminChecks(BaseModelAdminChecks):
    def check(self, admin_obj: BaseModelAdmin, **kwargs: Any) -> Sequence[CheckMessage]: ...

class InlineModelAdminChecks(BaseModelAdminChecks):
    def check(self, inline_obj: BaseModelAdmin, **kwargs: Any) -> Sequence[CheckMessage]: ...  # type: ignore

def must_be(type: Any, option: Any, obj: Any, id: Any): ...
def must_inherit_from(parent: Any, option: Any, obj: Any, id: Any): ...
def refer_to_missing_field(field: Any, option: Any, obj: Any, id: Any): ...
