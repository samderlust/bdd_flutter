import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The steps of the feature "Note auto-sync".
class NoteAutoSyncSteps {
  late WidgetTester tester;

  @Given('the user is on the editor screen for a draft note')
  Future<void> theUserIsOnTheEditorScreenForADraftNote() async {
    throw UnimplementedError(
      'Given the user is on the editor screen for a draft note',
    );
  }

  @Given('the note is not locked')
  Future<void> theNoteIsNotLocked() async {
    throw UnimplementedError('And the note is not locked');
  }

  @Given('the user is on the {string} section')
  Future<void> theUserIsOnTheSection(String arg1) async {
    throw UnimplementedError('Given the user is on the "Title" section');
  }

  @When('the user types {string} in the {string} field')
  Future<void> theUserTypesInTheField(String arg1, String arg2) async {
    throw UnimplementedError(
      'When the user types "Groceries" in the "Note Title" field',
    );
  }

  @When('waits {num} second without further input')
  Future<void> waitsSecondWithoutFurtherInput(num arg1) async {
    throw UnimplementedError('And waits 1 second without further input');
  }

  @Then('the app sends a syncNoteContent request with the current content')
  Future<void> theAppSendsASyncNoteContentRequestWithTheCurrentContent() async {
    throw UnimplementedError(
      'Then the app sends a syncNoteContent request with the current content',
    );
  }

  @Then('a {string} indicator appears')
  Future<void> aIndicatorAppears(String arg1) async {
    throw UnimplementedError('And a "Syncing..." indicator appears');
  }

  @Then(
    'once the sync succeeds the indicator changes to {string} with a checkmark',
  )
  Future<void> onceTheSyncSucceedsTheIndicatorChangesToWithACheckmark(
    String arg1,
  ) async {
    throw UnimplementedError(
      'And once the sync succeeds the indicator changes to "Synced" with a checkmark',
    );
  }

  @When('types {string} 200ms later')
  Future<void> types200msLater(String arg1) async {
    throw UnimplementedError('And types "r" 200ms later');
  }

  @Then('exactly one syncNoteContent request is sent')
  Future<void> exactlyOneSyncNoteContentRequestIsSent() async {
    throw UnimplementedError(
      'Then exactly one syncNoteContent request is sent',
    );
  }

  @Then('the content payload contains title: {string}')
  Future<void> theContentPayloadContainsTitle(String arg1) async {
    throw UnimplementedError('And the content payload contains title: "Groc"');
  }

  @Given('the {string} field already contains {string}')
  Future<void> theFieldAlreadyContains(String arg1, String arg2) async {
    throw UnimplementedError(
      'Given the "Note Title" field already contains "Groceries"',
    );
  }

  @Given('the last sync included title: {string}')
  Future<void> theLastSyncIncludedTitle(String arg1) async {
    throw UnimplementedError('And the last sync included title: "Groceries"');
  }

  @When(
    'the user focuses the {string} field and then leaves without changing it',
  )
  Future<void> theUserFocusesTheFieldAndThenLeavesWithoutChangingIt(
    String arg1,
  ) async {
    throw UnimplementedError(
      'When the user focuses the "Note Title" field and then leaves without changing it',
    );
  }

  @Then('no syncNoteContent request is sent')
  Future<void> noSyncNoteContentRequestIsSent() async {
    throw UnimplementedError('Then no syncNoteContent request is sent');
  }

  @Given('the user types {string} in {string} and a sync is in-flight')
  Future<void> theUserTypesInAndASyncIsInFlight(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'Given the user types "Groceries" in "Note Title" and a sync is in-flight',
    );
  }

  @When(
    'the user types {string} in {string} before the in-flight sync completes',
  )
  Future<void> theUserTypesInBeforeTheInFlightSyncCompletes(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'When the user types "Shopping" in "Note Title" before the in-flight sync completes',
    );
  }

  @When('waits {num} second')
  Future<void> waitsSecond(num arg1) async {
    throw UnimplementedError('And waits 1 second');
  }

  @Then('the in-flight sync for {string} is cancelled')
  Future<void> theInFlightSyncForIsCancelled(String arg1) async {
    throw UnimplementedError(
      'Then the in-flight sync for "Groceries" is cancelled',
    );
  }

  @Then('a new sync with title: {string} is sent')
  Future<void> aNewSyncWithTitleIsSent(String arg1) async {
    throw UnimplementedError('And a new sync with title: "Shopping" is sent');
  }

  @When('the syncNoteContent request fails and the user taps Retry')
  Future<void> theSyncNoteContentRequestFailsAndTheUserTapsRetry() async {
    throw UnimplementedError(
      'When the syncNoteContent request fails and the user taps Retry',
    );
  }

  @Then('the sync indicator first shows {string} with a {string} action')
  Future<void> theSyncIndicatorFirstShowsWithAAction(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'Then the sync indicator first shows "Sync failed" with a "Retry" action',
    );
  }

  @Then('after retry the request is re-sent and succeeds')
  Future<void> afterRetryTheRequestIsReSentAndSucceeds() async {
    throw UnimplementedError(
      'And after retry the request is re-sent and succeeds',
    );
  }

  @Given('the note is in {string} status')
  Future<void> theNoteIsInStatus(String arg1) async {
    throw UnimplementedError('Given the note is in "locked" status');
  }

  @When('the user views the note')
  Future<void> theUserViewsTheNote() async {
    throw UnimplementedError('When the user views the note');
  }

  @Then('no sync requests are sent regardless of field interactions')
  Future<void> noSyncRequestsAreSentRegardlessOfFieldInteractions() async {
    throw UnimplementedError(
      'Then no sync requests are sent regardless of field interactions',
    );
  }

  @Given('the user previously wrote title: {string} and body: {string}')
  Future<void> theUserPreviouslyWroteTitleAndBody(
    String arg1,
    String arg2,
  ) async {
    throw UnimplementedError(
      'Given the user previously wrote title: "Groceries" and body: "Milk and eggs"',
    );
  }

  @Given('those values were auto-synced to the server')
  Future<void> thoseValuesWereAutoSyncedToTheServer() async {
    throw UnimplementedError('And those values were auto-synced to the server');
  }

  @When('the user re-opens the note')
  Future<void> theUserReOpensTheNote() async {
    throw UnimplementedError('When the user re-opens the note');
  }

  @Then('the {string} field shows {string}')
  Future<void> theFieldShows(String arg1, String arg2) async {
    throw UnimplementedError('Then the "Note Title" field shows "Groceries"');
  }

  @Then(r'no sync is triggered on load \(content unchanged\)')
  Future<void> noSyncIsTriggeredOnLoadContentUnchanged() async {
    throw UnimplementedError(
      'And no sync is triggered on load (content unchanged)',
    );
  }

  @Given('the note has {num} required sections and {num} are filled')
  Future<void> theNoteHasRequiredSectionsAndAreFilled(
    num arg1,
    num arg2,
  ) async {
    throw UnimplementedError(
      'Given the note has 10 required sections and 3 are filled',
    );
  }

  @When('the user fills a 4th required section')
  Future<void> theUserFillsA4thRequiredSection() async {
    throw UnimplementedError('When the user fills a 4th required section');
  }

  @When('the auto-sync completes')
  Future<void> theAutoSyncCompletes() async {
    throw UnimplementedError('And the auto-sync completes');
  }

  @Then(
    'the progress indicator updates to reflect {num} of {num} required sections filled',
  )
  Future<void> theProgressIndicatorUpdatesToReflectOfRequiredSectionsFilled(
    num arg1,
    num arg2,
  ) async {
    throw UnimplementedError(
      'Then the progress indicator updates to reflect 4 of 10 required sections filled',
    );
  }

  @Given('the note model is empty')
  Future<void> theNoteModelIsEmpty() async {
    throw UnimplementedError('Given the note model is empty');
  }

  @When('onContentChanged is called with empty content')
  Future<void> onContentChangedIsCalledWithEmptyContent() async {
    throw UnimplementedError(
      'When onContentChanged is called with empty content',
    );
  }

  @Then('no request is sent')
  Future<void> noRequestIsSent() async {
    throw UnimplementedError('Then no request is sent');
  }

  @Given('a content change was made')
  Future<void> aContentChangeWasMade() async {
    throw UnimplementedError('Given a content change was made');
  }

  @When('cancel is called before the debounce fires')
  Future<void> cancelIsCalledBeforeTheDebounceFires() async {
    throw UnimplementedError('When cancel is called before the debounce fires');
  }
}
