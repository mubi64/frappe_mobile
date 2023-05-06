import 'package:flutter/material.dart';
import 'package:frappe_app/app/locator.dart';
import 'package:frappe_app/model/desk_sidebar_items_response.dart';
import 'package:frappe_app/services/location_service.dart';
import 'package:frappe_app/utils/frappe_alert.dart';
import 'package:frappe_app/utils/helpers.dart';
import 'package:frappe_app/widgets/frappe_button.dart';
import 'package:frappe_app/widgets/padded_card_list_tile.dart';
import 'package:frappe_app/widgets/user_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/frappe_palette.dart';
import '../../config/palette.dart';
import '../../model/config.dart';
import '../../model/desktop_page_response.dart';
import '../../services/api/api.dart';
import '../../utils/enums.dart';
import '../../widgets/header_app_bar.dart';
import '../base_view.dart';
import 'desk_viewmodel.dart';

// ignore: must_be_immutable
class DeskView extends StatelessWidget {
  DeskMessage? module;

  DeskView([
    this.module,
  ]);

  @override
  Widget build(BuildContext context) {

    return BaseView<DeskViewModel>(
      onModelReady: (model) {
        model.getData();
      },
      onModelClose: (model) {
        model.error = null;
        model.modulesByCategory.clear();
      },
      builder: (context, model, child) {
        if (model.state == ViewState.busy) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (model.hasError) {
          return handleError(
            onRetry: () {
              model.getData();
            },
            error: model.error!,
            context: context,
          );
        } else {
          if (module != null) {
            model.passedModule = module;
            module = null;
            model.getData();
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return Scaffold(
              drawer: Drawer(
                child: model.state == ViewState.busy
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Builder(
                        builder: (context) {
                          List<Widget> listItems = [];
                          model.modulesByCategory.forEach(
                            (category, modules) {
                              listItems.add(ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                title: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    color: FrappePalette.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                visualDensity: VisualDensity(
                                  vertical: -4,
                                ),
                              ));
                              modules.forEach(
                                (element) {
                                  listItems.add(
                                    ListTile(
                                      visualDensity: VisualDensity(
                                        vertical: -4,
                                      ),
                                      tileColor:
                                          model.currentModule == element.name
                                              ? Palette.bgColor
                                              : Colors.white,
                                      title: Text(
                                        element.label,
                                      ),
                                      onTap: () {
                                        model.switchModule(
                                          element,
                                        );

                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          );

                          return ListView(
                            children: listItems,
                          );
                        },
                      ),
              ),
              backgroundColor: Palette.bgColor,
              appBar: buildAppBar(
                context: context,
                title: model.currentModuleTitle,
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  model.getData();
                },
                child: Builder(
                  builder: (
                    context,
                  ) {
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: _generateChildren(
                        desktopPage: model.desktopPage,
                        model: model,
                        context: context,
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }
      },
    );
  }

  Widget _heading(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
        horizontal: 16,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _subHeading(String title) {
    return ListTile(
      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _shortcut({
    required ShortcutItem item,
    required DeskViewModel model,
    required BuildContext context,
  }) {
    return PaddedCardListTile(
      title: item.label,
      trailing: model.counts[item.label] != null ? ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 20,
            minWidth: 20,
            maxWidth: 80,
            maxHeight: 20,
          ),
          child: Container(
            color: Colors.grey[300],
            child: Text(
              model.counts[item.label].toString(),
              textAlign: TextAlign.center,
            ),
          )) : null,
      onTap: () async {
        model.navigateToView(
          doctype: item.linkTo,
          context: context,
        );
      },
    );
  }

  Widget _item({
    required CardItemLink item,
    required DeskViewModel model,
    required BuildContext context,
  }) {
    return ListTile(
      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
      title: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: FrappePalette.grey[100],
                ),
                width: 20,
                height: 20,
              ),
              Icon(
                Icons.circle,
                color: FrappePalette.grey[800],
                size: 6,
              ),
            ],
          ),
          SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              item.label,
            ),
          ),
        ],
      ),
      onTap: () {
        model.navigateToView(
          doctype: item.linkTo ?? item.name ?? "",
          context: context,
        );
      },
    );
  }

  List<Widget> _generateChildren({
    required DesktopPageResponse desktopPage,
    required DeskViewModel model,
    required BuildContext context,
  }) {
    List<Widget> widgets = [];

    if (desktopPage.message.shortcuts.items.isNotEmpty) {
      widgets.add(
        SizedBox(
          height: 20,
        ),
      );
      widgets.add(
        _heading("Your Shortcuts"),
      );

      widgets.addAll(desktopPage.message.shortcuts.items.where((item) {
        return item.type == "DocType";
      }).map<Widget>(
        (item) {
          return _shortcut(
            item: item,
            model: model,
            context: context,
          );
        },
      ).toList());

      widgets.add(
        SizedBox(
          height: 20,
        ),
      );
    }

    if (desktopPage.message.cards.items.isNotEmpty) {
      widgets.add(
        _heading("Masters"),
      );

      desktopPage.message.cards.items.forEach(
        (item) {
          if (item.hidden != 1)
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 0.5,
                      color: FrappePalette.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(
                      6.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        _subHeading(
                          item.label,
                        ),
                        ...item.links.where((item) {
                          return item.type != "DocType";
                        }).map(
                          (link) {
                            return _item(
                              item: link,
                              model: model,
                              context: context,
                            );
                          },
                        ).toList()
                      ],
                    ),
                  ),
                ),
              ),
            );

          widgets.add(
            SizedBox(
              height: 15,
            ),
          );
        },
      );
    }

    return widgets;
  }
}
