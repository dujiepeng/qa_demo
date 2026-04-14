import 'package:flutter/material.dart';

import '../../utils/app_route_observer.dart';

bool isAppLifecycleForeground(AppLifecycleState state) {
  return switch (state) {
    AppLifecycleState.resumed => true,
    AppLifecycleState.inactive => false,
    AppLifecycleState.hidden => false,
    AppLifecycleState.paused => false,
    AppLifecycleState.detached => false,
  };
}

class LogPanelVisibilityObserver with WidgetsBindingObserver, RouteAware {
  LogPanelVisibilityObserver({required this.onVisibilityChanged});

  final ValueChanged<bool> onVisibilityChanged;

  bool _appInForeground = true;
  bool _routeVisible = true;
  bool _effectiveVisibility = true;
  ModalRoute<dynamic>? _subscribedRoute;

  void attach(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _subscribedRoute)) {
      return;
    }
    if (_subscribedRoute != null) {
      appRouteObserver.unsubscribe(this);
    }
    _subscribedRoute = route;
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
      _routeVisible = route.isCurrent;
      _notifyIfChanged();
    }
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    if (_subscribedRoute != null) {
      appRouteObserver.unsubscribe(this);
      _subscribedRoute = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = isAppLifecycleForeground(state);
    _notifyIfChanged();
  }

  @override
  void didPush() {
    _routeVisible = true;
    _notifyIfChanged();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _notifyIfChanged();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _notifyIfChanged();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _notifyIfChanged();
  }

  void _notifyIfChanged() {
    final nextVisibility = _appInForeground && _routeVisible;
    if (nextVisibility == _effectiveVisibility) {
      return;
    }
    _effectiveVisibility = nextVisibility;
    onVisibilityChanged(nextVisibility);
  }
}
