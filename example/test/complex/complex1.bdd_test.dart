import 'package:flutter_test/flutter_test.dart';
import 'complex1.bdd_scenarios.dart';

void main() {
  group('Note auto-sync', () {
    testWidgets('Text change triggers auto-sync after 1-second debounce', (tester) async {
      final scenario = TextChangeTriggersAutoSyncAfter1SecondDebounceScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Text change triggers auto-sync after 1-second debounce
      // Given the user is on the "Title" section
      await scenario.theUserIsOnTheTitleSection(tester);
      // When the user types "Groceries" in the "Note Title" field
      await scenario.theUserTypesGroceriesInTheNoteTitleField(tester);
      // And waits 1 second without further input
      await scenario.waits1SecondWithoutFurtherInput(tester);
      // Then the app sends a syncNoteContent request with the current content
      await scenario.theAppSendsASyncnotecontentRequestWithTheCurrentContent(tester);
      // And a "Syncing..." indicator appears
      await scenario.aSyncingIndicatorAppears(tester);
      // And once the sync succeeds the indicator changes to "Synced" with a checkmark
      await scenario.onceTheSyncSucceedsTheIndicatorChangesToSyncedWithACheckmark(tester);
    });
    testWidgets('Rapid typing batches into a single sync', (tester) async {
      final scenario = RapidTypingBatchesIntoASingleSyncScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Rapid typing batches into a single sync
      // Given the user is on the "Title" section
      await scenario.theUserIsOnTheTitleSection(tester);
      // When the user types "G" in the "Note Title" field
      await scenario.theUserTypesGInTheNoteTitleField(tester);
      // And types "r" 200ms later
      await scenario.typesR200msLater(tester);
      // And types "o" 200ms later
      await scenario.typesO200msLater(tester);
      // And types "c" 200ms later
      await scenario.typesC200msLater(tester);
      // And waits 1 second without further input
      await scenario.waits1SecondWithoutFurtherInput(tester);
      // Then exactly one syncNoteContent request is sent
      await scenario.exactlyOneSyncnotecontentRequestIsSent(tester);
      // And the content payload contains title: "Groc"
      await scenario.theContentPayloadContainsTitleGroc(tester);
    });
    testWidgets('Identical content does not trigger a sync', (tester) async {
      final scenario = IdenticalContentDoesNotTriggerASyncScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Identical content does not trigger a sync
      // Given the "Note Title" field already contains "Groceries"
      await scenario.theNoteTitleFieldAlreadyContainsGroceries(tester);
      // And the last sync included title: "Groceries"
      await scenario.theLastSyncIncludedTitleGroceries(tester);
      // When the user focuses the "Note Title" field and then leaves without changing it
      await scenario.theUserFocusesTheNoteTitleFieldAndThenLeavesWithoutChangingIt(tester);
      // Then no syncNoteContent request is sent
      await scenario.noSyncnotecontentRequestIsSent(tester);
    });
    testWidgets('New sync cancels in-flight sync', (tester) async {
      final scenario = NewSyncCancelsInFlightSyncScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: New sync cancels in-flight sync
      // Given the user types "Groceries" in "Note Title" and a sync is in-flight
      await scenario.theUserTypesGroceriesInNoteTitleAndASyncIsInFlight(tester);
      // When the user types "Shopping" in "Note Title" before the in-flight sync completes
      await scenario.theUserTypesShoppingInNoteTitleBeforeTheInFlightSyncCompletes(tester);
      // And waits 1 second
      await scenario.waits1Second(tester);
      // Then the in-flight sync for "Groceries" is cancelled
      await scenario.theInFlightSyncForGroceriesIsCancelled(tester);
      // And a new sync with title: "Shopping" is sent
      await scenario.aNewSyncWithTitleShoppingIsSent(tester);
    });
    testWidgets('Sync failure shows error with retry', (tester) async {
      final scenario = SyncFailureShowsErrorWithRetryScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Sync failure shows error with retry
      // Given the user types "Groceries" in the "Note Title" field
      await scenario.theUserTypesGroceriesInTheNoteTitleField(tester);
      // And waits 1 second
      await scenario.waits1Second(tester);
      // When the syncNoteContent request fails and the user taps Retry
      await scenario.theSyncnotecontentRequestFailsAndTheUserTapsRetry(tester);
      // Then the sync indicator first shows "Sync failed" with a "Retry" action
      await scenario.theSyncIndicatorFirstShowsSyncFailedWithARetryAction(tester);
      // And after retry the request is re-sent and succeeds
      await scenario.afterRetryTheRequestIsReSentAndSucceeds(tester);
    });
    testWidgets('Auto-sync is skipped for locked notes', (tester) async {
      final scenario = AutoSyncIsSkippedForLockedNotesScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Auto-sync is skipped for locked notes
      // Given the note is in "locked" status
      await scenario.theNoteIsInLockedStatus(tester);
      // When the user views the note
      await scenario.theUserViewsTheNote(tester);
      // Then no sync requests are sent regardless of field interactions
      await scenario.noSyncRequestsAreSentRegardlessOfFieldInteractions(tester);
    });
    testWidgets('Reopening a note restores synced values', (tester) async {
      final scenario = ReopeningANoteRestoresSyncedValuesScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Reopening a note restores synced values
      // Given the user previously wrote title: "Groceries" and body: "Milk and eggs"
      await scenario.theUserPreviouslyWroteTitleGroceriesAndBodyMilkAndEggs(tester);
      // And those values were auto-synced to the server
      await scenario.thoseValuesWereAutoSyncedToTheServer(tester);
      // When the user re-opens the note
      await scenario.theUserReOpensTheNote(tester);
      // Then the "Note Title" field shows "Groceries"
      await scenario.theNoteTitleFieldShowsGroceries(tester);
      // And the "Body" field shows "Milk and eggs"
      await scenario.theBodyFieldShowsMilkAndEggs(tester);
      // And no sync is triggered on load (content unchanged)
      await scenario.noSyncIsTriggeredOnLoadContentUnchanged(tester);
    });
    testWidgets('Word count updates after sync', (tester) async {
      final scenario = WordCountUpdatesAfterSyncScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Word count updates after sync
      // Given the note has 10 required sections and 3 are filled
      await scenario.theNoteHas10RequiredSectionsAnd3AreFilled(tester);
      // When the user fills a 4th required section
      await scenario.theUserFillsA4thRequiredSection(tester);
      // And the auto-sync completes
      await scenario.theAutoSyncCompletes(tester);
      // Then the progress indicator updates to reflect 4 of 10 required sections filled
      await scenario.theProgressIndicatorUpdatesToReflect4Of10RequiredSectionsFilled(tester);
    });
    testWidgets('Empty content is not synced', (tester) async {
      final scenario = EmptyContentIsNotSyncedScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Empty content is not synced
      // Given the note model is empty
      await scenario.theNoteModelIsEmpty(tester);
      // When onContentChanged is called with empty content
      await scenario.oncontentchangedIsCalledWithEmptyContent(tester);
      // Then no request is sent
      await scenario.noRequestIsSent(tester);
    });
    testWidgets('Cancel stops pending debounce', (tester) async {
      final scenario = CancelStopsPendingDebounceScenario();
      final background = NoteAutoSyncBackground();
      //Background: 
      await background.theUserIsOnTheEditorScreenForADraftNote();
      await background.theNoteIsNotLocked();
      //Scenario: Cancel stops pending debounce
      // Given a content change was made
      await scenario.aContentChangeWasMade(tester);
      // When cancel is called before the debounce fires
      await scenario.cancelIsCalledBeforeTheDebounceFires(tester);
      // Then no request is sent
      await scenario.noRequestIsSent(tester);
    });
  });
}
