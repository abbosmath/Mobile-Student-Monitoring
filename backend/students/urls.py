from django.urls import path
from students.views.groups import (
    groups_list,
    group_create,
    group_detail,
    group_edit,
    group_delete,
    add_student_to_group,
    remove_student_from_group,
)
from students.views.stats import stats_overview, stats_group
from students.views.market import (
    market_items_list,
    market_item_create,
    market_item_edit,
    market_item_delete,
    market_orders_list,
    market_order_update_status,
)

urlpatterns = [
    path("", groups_list, name="groups_list"),
    path("create/", group_create, name="group_create"),
    path("<int:group_id>/", group_detail, name="group_detail"),
    path("<int:group_id>/edit/", group_edit, name="group_edit"),
    path("<int:group_id>/delete/", group_delete, name="group_delete"),
    path("<int:group_id>/add-student/", add_student_to_group, name="add_student_to_group"),
    path("<int:group_id>/remove-student/<int:student_id>/", remove_student_from_group, name="remove_student_from_group"),
    path("stats/", stats_overview, name="stats_overview"),
    path("stats/<int:group_id>/", stats_group, name="stats_group"),
    path("market/", market_items_list, name="market_items_list"),
    path("market/create/", market_item_create, name="market_item_create"),
    path("market/<int:item_id>/edit/", market_item_edit, name="market_item_edit"),
    path("market/<int:item_id>/delete/", market_item_delete, name="market_item_delete"),
    path("market/orders/", market_orders_list, name="market_orders_list"),
    path("market/orders/<int:order_id>/status/", market_order_update_status, name="market_order_update_status"),
]

