import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:cashtrack/services/profile_store.dart';
import 'package:cashtrack/services/profile_sync_service.dart';

void main() {
  group('ProfileSyncService.decide', () {
    const older = '2026-01-01T00:00:00.000Z';
    const newer = '2026-02-01T00:00:00.000Z';
    ProfileSyncAction d(String? local, String? remote) =>
        ProfileSyncService.decide(
            localUpdatedAt: local, remoteUpdatedAt: remote);

    test('nothing anywhere -> none', () {
      expect(d(null, null), ProfileSyncAction.none);
    });
    test('only local -> push, only remote -> pull', () {
      expect(d(older, null), ProfileSyncAction.push);
      expect(d(null, older), ProfileSyncAction.pull);
    });
    test('newest side wins', () {
      expect(d(older, newer), ProfileSyncAction.pull);
      expect(d(newer, older), ProfileSyncAction.push);
    });
    test('equal timestamps (incl. different offsets) -> none', () {
      expect(d(older, older), ProfileSyncAction.none);
      expect(d('2026-01-01T06:00:00.000+06:00', older), ProfileSyncAction.none);
    });
    test('unparseable remote is treated as missing', () {
      expect(d(older, 'garbage'), ProfileSyncAction.push);
    });
  });

  group('remote validation', () {
    test('accepts a well-formed info doc and trims values', () {
      final r = ProfileSyncService.parseRemoteInfo({
        'fullName': ' Zahid ',
        'phone': '01712345678',
        'dob': '07 Mar 1998',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });
      expect(r, isNotNull);
      expect(r!.fields['fullName'], 'Zahid');
    });

    test('rejects wrong types, oversize values and bad timestamps', () {
      const ok = '2026-01-01T00:00:00.000Z';
      expect(ProfileSyncService.parseRemoteInfo(null), isNull);
      expect(
          ProfileSyncService.parseRemoteInfo(
              {'fullName': 5, 'phone': '', 'dob': '', 'updatedAt': ok}),
          isNull);
      expect(
          ProfileSyncService.parseRemoteInfo(
              {'fullName': 'x' * 61, 'phone': '', 'dob': '', 'updatedAt': ok}),
          isNull);
      expect(
          ProfileSyncService.parseRemoteInfo(
              {'fullName': 'a', 'phone': '', 'dob': '', 'updatedAt': 'nope'}),
          isNull);
    });

    test('photo: empty data is a valid removal, oversize is rejected', () {
      const ok = '2026-01-01T00:00:00.000Z';
      expect(
          ProfileSyncService.parseRemotePhoto({'data': '', 'updatedAt': ok})!
              .data,
          '');
      expect(
          ProfileSyncService.parseRemotePhoto({
            'data': 'a' * (ProfileStore.maxPhotoBase64Length + 1),
            'updatedAt': ok,
          }),
          isNull);
    });
  });

  group('ProfileStore', () {
    late Directory dir;
    late Box box;
    late ProfileStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('profile_store_test');
      Hive.init(dir.path);
      box = await Hive.openBox('profile_store_test');
      store = ProfileStore(openBox: () async => box);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await dir.delete(recursive: true);
    });

    test('keys are scoped per account', () async {
      await store.write('u1', 'fullName', 'One');
      await store.write(null, 'fullName', 'Guest');
      expect((await store.read('u1'))['fullName'], 'One');
      expect((await store.read('u2'))['fullName'], '');
      expect((await store.read(null))['fullName'], 'Guest');
    });

    test('writes stamp the matching sync marker only', () async {
      expect(await store.infoUpdatedAt('u1'), isNull);
      await store.write('u1', 'email', 'a@b.co'); // email is not synced
      expect(await store.infoUpdatedAt('u1'), isNull);
      await store.write('u1', 'phone', '01712345678');
      expect(await store.infoUpdatedAt('u1'), isNotNull);
      expect(await store.photoUpdatedAt('u1'), isNull);
      await store.write('u1', 'photoBase64', '');
      expect(await store.photoUpdatedAt('u1'), isNotNull);
    });

    test('unknown fields are rejected', () async {
      expect(() => store.write('u1', 'bio', 'x'), throwsArgumentError);
    });

    test('applyRemoteInfo keeps the remote timestamp', () async {
      const at = '2026-03-01T00:00:00.000Z';
      await store.applyRemoteInfo(
          'u1', {'fullName': 'Remote', 'phone': '', 'dob': ''}, at);
      expect((await store.read('u1'))['fullName'], 'Remote');
      expect(await store.infoUpdatedAt('u1'), at);
    });

    test('purgeRetiredFields removes address/occupation/bio only', () async {
      await box.putAll({
        'profile_u1_address': 'Dhaka',
        'profile_u1_bio': 'hi',
        'profile_occupation': 'dev',
        'profile_u1_full_name': 'Keep',
        'profile_u2_bio': 'other account',
      });
      await store.purgeRetiredFields('u1');
      expect(box.containsKey('profile_u1_address'), isFalse);
      expect(box.containsKey('profile_u1_bio'), isFalse);
      expect(box.containsKey('profile_occupation'), isFalse);
      expect(box.get('profile_u1_full_name'), 'Keep');
      // Another account's keys are purged when that account loads.
      expect(box.containsKey('profile_u2_bio'), isTrue);
    });
  });
}
