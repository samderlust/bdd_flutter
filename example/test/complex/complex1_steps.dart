import 'package:flutter_test/flutter_test.dart';

import 'complex1.bdd_steps.g.dart';

/// The steps of the feature "Note auto-sync".
class NoteAutoSyncSteps implements NoteAutoSyncStepsContract {
  @override
  late WidgetTester tester;

  @override
  Future<void> theUserIsOnTheEditorScreenForADraftNote() async {
    throw UnimplementedError(
      'Given the user is on the editor screen for a draft note',
    );
  }

  @override
  Future<void> theNoteIsNotLocked() async {
    throw UnimplementedError('And the note is not locked');
  }

  @override
  Future<void> theUserIsOnTheSection(String arg1) async {
    throw UnimplementedError('Given the user is on the "Title" section');
  }

  @override
  Future<void> theUserTypesInTheField(String arg1, String arg2) async {
    throw UnimplementedError(
      'When the user types "Groceries" in the "Note Title" field',
    );
  }

  @override
  Future<void> waitsSecondWithoutFurtherInput(num arg1) async {
    throw UnimplementedError('And waits 1 second without further input');
  }

  @override
  Future<void> theAppSendsASyncNoteContentRequestWithTheCurrentContent() async {
    throw UnimplementedError(
      'Then the app sends a syncNoteContent request with the current content',
    );
  }

  @override
  Future<void> aIndicatorAppears(String arg1) async {
    throw UnimplementedError('And a "Syncing..." indicator appears');
  }

  @override
  Future<void> onceTheSyncSucceedsTheIndicatorChangesToWithACheckmark(
    String arg1,
  ) async {
    throw UnimplementedError(
      'And once the sync succeeds the indicator changes to "Synced" with a checkmark',
    );
  }

  @override
  Future<void> types200msLater(String arg1) async {
    throw UnimplementedError('And types "r" 200ms later');
  }

  @override
  Future<void> exactlyOneSyncNoteContentRequestIsSent() async {
    throw UnimplementedError(
      'Then exactly one syncNoteContent request is sent',
    );
  }

  @override
  Future<void> theContentPayloadContainsTitle(String arg1) async {
    throw UnimplementedError('And the content payload contains title: "Groc"');
  }

  @override
  Future<void> theFieldAlreadyContains(String arg1, String arg2) async {
    throw UnimplementedError(
      'Given the "Note Title" field already contains "Groceries"',
    );
  }

  @override
  Future<void> theLastSyncIncludedTitle(String arg1) async {
    throw UnimplementedError('And the last sync included title: "Groceries"');
  }

  @override
  Future<void> theUserFocusesTheFieldAndThenLeavesWithoutChangingIt(
    String arg1,
  ) async {
    throw UnimplementedError(
      'When the user focuses the "Note Title" field and then leaves without changing it',
    );
  }

  @override
  Future<void> noSyncNoteContentRequestIsSent() async {
    throw UnimplementedError('Then no syncNoteContent request is sent');
  }

  @override
  Future<void> theUserTypesInAndASyncIsInFlight(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'Given the user types "Groceries" in "Note Title" and a sync is in-flight',
    );
  }

  @override
  Future<void> theUserTypesInBeforeTheInFlightSyncCompletes(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'When the user types "Shopping" in "Note Title" before the in-flight sync completes',
    );
  }

  @override
  Future<void> waitsSecond(num arg1) async {
    throw UnimplementedError('And waits 1 second');
  }

  @override
  Future<void> theInFlightSyncForIsCancelled(String arg1) async {
    throw UnimplementedError(
      'Then the in-flight sync for "Groceries" is cancelled',
    );
  }

  @override
  Future<void> aNewSyncWithTitleIsSent(String arg1) async {
    throw UnimplementedError('And a new sync with title: "Shopping" is sent');
  }

  @override
  Future<void> theSyncNoteContentRequestFailsAndTheUserTapsRetry() async {
    throw UnimplementedError(
      'When the syncNoteContent request fails and the user taps Retry',
    );
  }

  @override
  Future<void> theSyncIndicatorFirstShowsWithAAction(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'Then the sync indicator first shows "Sync failed" with a "Retry" action',
    );
  }

  @override
  Future<void> afterRetryTheRequestIsReSentAndSucceeds() async {
    throw UnimplementedError(
      'And after retry the request is re-sent and succeeds',
    );
  }

  @override
  Future<void> theNoteIsInStatus(String arg1) async {
    throw UnimplementedError('Given the note is in "locked" status');
  }

  @override
  Future<void> theUserViewsTheNote() async {
    throw UnimplementedError('When the user views the note');
  }

  @override
  Future<void> noSyncRequestsAreSentRegardlessOfFieldInteractions() async {
    throw UnimplementedError(
      'Then no sync requests are sent regardless of field interactions',
    );
  }

  @override
  Future<void> theUserPreviouslyWroteTitleAndBody(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'Given the user previously wrote title: "Groceries" and body: "Milk and eggs"',
    );
  }

  @override
  Future<void> thoseValuesWereAutoSyncedToTheServer() async {
    throw UnimplementedError('And those values were auto-synced to the server');
  }

  @override
  Future<void> theUserReOpensTheNote() async {
    throw UnimplementedError('When the user re-opens the note');
  }

  @override
  Future<void> theFieldShows(String arg1, String arg2) async {
    throw UnimplementedError('Then the "Note Title" field shows "Groceries"');
  }

  @override
  Future<void> noSyncIsTriggeredOnLoadContentUnchanged() async {
    throw UnimplementedError(
      'And no sync is triggered on load (content unchanged)',
    );
  }

  @override
  Future<void> theNoteHasRequiredSectionsAndAreFilled(
    num arg1,
    num arg2,
  ) async {
    throw UnimplementedError(
      'Given the note has 10 required sections and 3 are filled',
    );
  }

  @override
  Future<void> theUserFillsA4thRequiredSection() async {
    throw UnimplementedError('When the user fills a 4th required section');
  }

  @override
  Future<void> theAutoSyncCompletes() async {
    throw UnimplementedError('And the auto-sync completes');
  }

  @override
  Future<void> theProgressIndicatorUpdatesToReflectOfRequiredSectionsFilled(
    num arg1,
    num arg2,
  ) async {
    throw UnimplementedError(
      'Then the progress indicator updates to reflect 4 of 10 required sections filled',
    );
  }

  @override
  Future<void> theNoteModelIsEmpty() async {
    throw UnimplementedError('Given the note model is empty');
  }

  @override
  Future<void> onContentChangedIsCalledWithEmptyContent() async {
    throw UnimplementedError(
      'When onContentChanged is called with empty content',
    );
  }

  @override
  Future<void> noRequestIsSent() async {
    throw UnimplementedError('Then no request is sent');
  }

  @override
  Future<void> aContentChangeWasMade() async {
    throw UnimplementedError('Given a content change was made');
  }

  @override
  Future<void> cancelIsCalledBeforeTheDebounceFires() async {
    throw UnimplementedError('When cancel is called before the debounce fires');
  }
}
