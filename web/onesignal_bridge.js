window.OneSignalDeferred = window.OneSignalDeferred || [];

window.__opadocaPush = {
  _ready: null,
  _os: null,
  _clickCbs: [],
  _subCbs: [],
  _clickBound: false,
  _subBound: false,

  init: function (appId) {
    var self = this;
    if (self._ready) return self._ready;
    self._ready = new Promise(function (resolve) {
      var settled = false;
      var finish = function (ok) {
        if (settled) return;
        settled = true;
        resolve(!!ok);
      };

      setTimeout(function () {
        if (settled) return;
        if (!self._os) {
          console.warn('[OneSignal] init timeout — o app segue sem push');
        }
        finish(!!self._os);
      }, 8000);

      try {
        window.OneSignalDeferred = window.OneSignalDeferred || [];
        window.OneSignalDeferred.push(async function (OneSignal) {
          try {
            await OneSignal.init({
              appId: appId,
              allowLocalhostAsSecureOrigin: true,
              serviceWorkerPath: 'OneSignalSDKWorker.js',
              serviceWorkerParam: { scope: '/' },
            });
            self._os = OneSignal;
            self._bindSubscription();
            self._bindClick();
            finish(true);
          } catch (err) {
            console.warn('[OneSignal] init failed', err);
            finish(false);
          }
        });
      } catch (err) {
        console.warn('[OneSignal] deferred push failed', err);
        finish(false);
      }
    });
    return self._ready;
  },

  login: async function (userId) {
    if (!this._os) return;
    await this._os.login(userId);
  },

  logout: async function () {
    if (!this._os) return;
    await this._os.logout();
  },

  requestPermission: async function () {
    if (!this._os) return false;
    return await this._os.Notifications.requestPermission();
  },

  subscriptionId: function () {
    try {
      return this._os && this._os.User && this._os.User.PushSubscription
        ? this._os.User.PushSubscription.id || null
        : null;
    } catch (_) {
      return null;
    }
  },

  onSubscriptionChange: function (callback) {
    this._subCbs.push(callback);
    this._bindSubscription();
  },

  onNotificationClick: function (callback) {
    this._clickCbs.push(callback);
    this._bindClick();
  },

  _bindSubscription: function () {
    if (!this._os || this._subBound) return;
    this._subBound = true;
    var self = this;
    this._os.User.PushSubscription.addEventListener('change', function (event) {
      var id = event && event.current && event.current.id;
      if (!id) return;
      self._subCbs.forEach(function (cb) { cb(id); });
    });
  },

  _bindClick: function () {
    if (!this._os || this._clickBound) return;
    this._clickBound = true;
    var self = this;
    this._os.Notifications.addEventListener('click', function (event) {
      var data = (event && event.notification && event.notification.additionalData) || {};
      var json = JSON.stringify(data);
      self._clickCbs.forEach(function (cb) { cb(json); });
    });
  },
};
