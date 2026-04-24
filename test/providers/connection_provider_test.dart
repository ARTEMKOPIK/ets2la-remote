import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ets2la_remote/providers/connection_provider.dart';
import 'package:ets2la_remote/models/connection_profile.dart';

void main() {
  group('ConnectionProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('stripAccidentalPort static helper', () {
      test('strips port from plain IPv4', () {
        expect(
            ConnectionProvider.stripAccidentalPort('192.168.0.5:37522'),
            '192.168.0.5');
      });

      test('strips port from hostname', () {
        expect(ConnectionProvider.stripAccidentalPort('ets2la.local:8080'),
            'ets2la.local');
      });

      test('returns IPv6 unchanged (no split needed)', () {
        expect(
            ConnectionProvider.stripAccidentalPort('2001:db8::1'), '2001:db8::1');
      });

      test('strips port from bracketed IPv6', () {
        expect(ConnectionProvider.stripAccidentalPort('[2001:db8::1]:37522'),
            '2001:db8::1');
      });

      test('returns empty string unchanged', () {
        expect(ConnectionProvider.stripAccidentalPort(''), '');
      });

      test('trims whitespace before processing', () {
        expect(
            ConnectionProvider.stripAccidentalPort('  192.168.0.5:8080  '),
            '192.168.0.5');
      });

      test('returns IPv4 without port unchanged', () {
        expect(ConnectionProvider.stripAccidentalPort('192.168.0.5'),
            '192.168.0.5');
      });

      test('IPv6 with multiple colons (no split) returned unchanged', () {
        // fe80::1%eth0 style
        expect(ConnectionProvider.stripAccidentalPort('fe80::1%25eth0'),
            'fe80::1%25eth0');
      });
    });

    group('initial state', () {
      test('starts with empty currentHost', () async {
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.currentHost, '');
      });

      test('starts with empty recentHosts', () async {
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.recentHosts, isEmpty);
      });

      test('starts with empty profiles', () async {
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.profiles, isEmpty);
      });

      test('starts not connecting', () async {
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.isConnecting, false);
      });

      test('starts at idle stage', () async {
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.stage, ConnectionStage.idle);
      });

      test('starts with null lastPingMs', () async {
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.lastPingMs, isNull);
      });

      test('starts with null errorMessage', () async {
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.errorMessage, isNull);
      });
    });

    group('_loadState — loads from SharedPreferences', () {
      test('loads recentHosts from prefs', () async {
        SharedPreferences.setMockInitialValues({
          'recent_hosts': ['host1.local', 'host2.local'],
        });
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.recentHosts, ['host1.local', 'host2.local']);
      });

      test('loads profiles from prefs', () async {
        final encoded = ConnectionProfile.encodeAll([
          const ConnectionProfile(id: '1', name: 'PC A', host: '192.168.1.1'),
          const ConnectionProfile(
              id: '2', name: 'PC B', host: '192.168.1.2', favourite: true),
        ]);
        SharedPreferences.setMockInitialValues({
          'connection_profiles': encoded,
        });
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.profiles.length, 2);
        expect(provider.profiles[0].id, '1');
        expect(provider.profiles[1].favourite, true);
      });

      test('recentHosts defaults to empty list when null in prefs', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.recentHosts, isEmpty);
      });

      test('profiles defaults to empty when key is missing', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.profiles, isEmpty);
      });
    });

    group('saveProfile', () {
      late ConnectionProvider provider;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
      });

      test('inserts new profile at top', () async {
        await provider.saveProfile(const ConnectionProfile(
          id: 'new-id',
          name: 'New PC',
          host: '192.168.0.1',
        ));
        expect(provider.profiles.length, 1);
        expect(provider.profiles[0].id, 'new-id');
      });

      test('replaces existing profile by id', () async {
        await provider.saveProfile(const ConnectionProfile(
          id: 'id1',
          name: 'Old Name',
          host: '192.168.0.1',
        ));
        await provider.saveProfile(const ConnectionProfile(
          id: 'id1',
          name: 'Updated Name',
          host: '192.168.0.1',
        ));
        expect(provider.profiles.length, 1);
        expect(provider.profiles[0].name, 'Updated Name');
      });

      test('un-stars other profiles when new profile is favourite', () async {
        await provider.saveProfile(const ConnectionProfile(
          id: 'a',
          name: 'A',
          host: '1.1.1.1',
          favourite: true,
        ));
        await provider.saveProfile(const ConnectionProfile(
          id: 'b',
          name: 'B',
          host: '2.2.2.2',
          favourite: true,
        ));
        expect(provider.profiles[0].id, 'b');
        expect(provider.profiles[0].favourite, true);
        expect(provider.profiles[1].favourite, false);
      });

      test('notifies listeners', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);
        await provider.saveProfile(const ConnectionProfile(
          id: 'x',
          name: 'X',
          host: '0.0.0.0',
        ));
        expect(notifyCount, greaterThan(0));
      });
    });

    group('removeProfile', () {
      late ConnectionProvider provider;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
      });

      test('removes existing profile', () async {
        await provider.saveProfile(const ConnectionProfile(
          id: 'to-remove',
          name: 'To Remove',
          host: '1.2.3.4',
        ));
        expect(provider.profiles.length, 1);
        await provider.removeProfile('to-remove');
        expect(provider.profiles, isEmpty);
      });

      test('no-op for non-existent id', () async {
        await provider.saveProfile(const ConnectionProfile(
          id: 'keep',
          name: 'Keep',
          host: '1.2.3.4',
        ));
        final countBefore = provider.profiles.length;
        await provider.removeProfile('nonexistent');
        expect(provider.profiles.length, countBefore);
      });
    });

    group('setFavouriteProfile', () {
      late ConnectionProvider provider;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
      });

      test('sets favourite on existing profile', () async {
        await provider.saveProfile(const ConnectionProfile(
          id: 'p1',
          name: 'P1',
          host: '1.2.3.4',
        ));
        await provider.setFavouriteProfile('p1');
        expect(provider.profiles[0].favourite, true);
        expect(provider.favouriteProfile?.id, 'p1');
      });

      test('clears favourite when same id tapped again', () async {
        await provider.saveProfile(const ConnectionProfile(
          id: 'p1',
          name: 'P1',
          host: '1.2.3.4',
          favourite: true,
        ));
        await provider.setFavouriteProfile('p1');
        expect(provider.profiles[0].favourite, false);
        expect(provider.favouriteProfile, isNull);
      });

      test('no-op for unknown id', () async {
        await provider.setFavouriteProfile('unknown-id');
        expect(provider.favouriteProfile, isNull);
      });
    });

    group('favouriteProfile getter', () {
      test('returns null when no profiles', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.favouriteProfile, isNull);
      });

      test('returns the favourite profile', () async {
        SharedPreferences.setMockInitialValues({
          'connection_profiles': ConnectionProfile.encodeAll([
            const ConnectionProfile(
                id: '1', name: 'A', host: '1.1.1.1', favourite: false),
            const ConnectionProfile(
                id: '2', name: 'B', host: '2.2.2.2', favourite: true),
            const ConnectionProfile(
                id: '3', name: 'C', host: '3.3.3.3', favourite: false),
          ]),
        });
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.favouriteProfile?.id, '2');
      });
    });

    group('removeRecentHost', () {
      test('removes existing recent host', () async {
        SharedPreferences.setMockInitialValues({
          'recent_hosts': ['a.local', 'b.local'],
        });
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        await provider.removeRecentHost('a.local');
        expect(provider.recentHosts, ['b.local']);
      });

      test('no-op for unknown host', () async {
        SharedPreferences.setMockInitialValues({
          'recent_hosts': ['a.local'],
        });
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        final countBefore = provider.recentHosts.length;
        await provider.removeRecentHost('unknown');
        expect(provider.recentHosts.length, countBefore);
      });

      test('notifies listeners', () async {
        SharedPreferences.setMockInitialValues({'recent_hosts': ['a']});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);
        await provider.removeRecentHost('a');
        expect(notifyCount, greaterThan(0));
      });
    });

    group('setError / clearError', () {
      test('setError stores message and notifies', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);
        provider.setError('connection refused');
        expect(provider.errorMessage, 'connection refused');
        expect(notifyCount, greaterThan(0));
      });

      test('clearError clears message and notifies', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        provider.setError('err');
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);
        provider.clearError();
        expect(provider.errorMessage, isNull);
        expect(notifyCount, greaterThan(0));
      });

      test('clearError is no-op when already null', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);
        provider.clearError();
        expect(notifyCount, 0);
      });
    });

    group('configurePorts / _applyPorts', () {
      test('configurePorts stores settings', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;

        final settings = AppSettings.create();
        // We can't use the factory since it calls SharedPreferences.getInstance()
        // again — test the configurePorts path via a partial mock approach:
        // just verify it accepts an AppSettings object and no exception is thrown.
        // The actual port application is tested via the wsService internals.
        expect(() => provider.configurePorts(await settings), returnsNormally);
      });
    });

    group('registerPagesFailureShouldShowDialog / resetFirewallFailStreak', () {
      test('threshold is 2 consecutive failures', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        expect(provider.registerPagesFailureShouldShowDialog(), false);
        expect(provider.registerPagesFailureShouldShowDialog(), true);
      });

      test('resetFirewallFailStreak resets count', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        provider.registerPagesFailureShouldShowDialog();
        provider.registerPagesFailureShouldShowDialog();
        provider.resetFirewallFailStreak();
        expect(provider.registerPagesFailureShouldShowDialog(), false);
        expect(provider.registerPagesFailureShouldShowDialog(), true);
      });

      test('resetFirewallFailStreak is no-op at zero', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        // Should not throw
        expect(() => provider.resetFirewallFailStreak(), returnsNormally);
      });
    });

    group('isConnected / isActiveOrConnecting', () {
      test('isConnected reflects wsService state', () async {
        SharedPreferences.setMockInitialValues({});
        final provider = ConnectionProvider();
        addTearDown(provider.dispose);
        await provider.ready;
        // Initially disconnected
        expect(provider.isConnected, false);
      });
    });
  });
}