Feature: Note auto-sync

  Background:
    Given the user is on the editor screen for a draft note
    And the note is not locked

  Scenario: Text change triggers auto-sync after 1-second debounce
    Given the user is on the "Title" section
    When the user types "Groceries" in the "Note Title" field
    And waits 1 second without further input
    Then the app sends a syncNoteContent request with the current content
    And a "Syncing..." indicator appears
    And once the sync succeeds the indicator changes to "Synced" with a checkmark

  Scenario: Rapid typing batches into a single sync
    Given the user is on the "Title" section
    When the user types "G" in the "Note Title" field
    And types "r" 200ms later
    And types "o" 200ms later
    And types "c" 200ms later
    And waits 1 second without further input
    Then exactly one syncNoteContent request is sent
    And the content payload contains title: "Groc"

  Scenario: Identical content does not trigger a sync
    Given the "Note Title" field already contains "Groceries"
    And the last sync included title: "Groceries"
    When the user focuses the "Note Title" field and then leaves without changing it
    Then no syncNoteContent request is sent

  Scenario: New sync cancels in-flight sync
    Given the user types "Groceries" in "Note Title" and a sync is in-flight
    When the user types "Shopping" in "Note Title" before the in-flight sync completes
    And waits 1 second
    Then the in-flight sync for "Groceries" is cancelled
    And a new sync with title: "Shopping" is sent

  Scenario: Sync failure shows error with retry
    Given the user types "Groceries" in the "Note Title" field
    And waits 1 second
    When the syncNoteContent request fails and the user taps Retry
    Then the sync indicator first shows "Sync failed" with a "Retry" action
    And after retry the request is re-sent and succeeds

  Scenario: Auto-sync is skipped for locked notes
    Given the note is in "locked" status
    When the user views the note
    Then no sync requests are sent regardless of field interactions

  Scenario: Reopening a note restores synced values
    Given the user previously wrote title: "Groceries" and body: "Milk and eggs"
    And those values were auto-synced to the server
    When the user re-opens the note
    Then the "Note Title" field shows "Groceries"
    And the "Body" field shows "Milk and eggs"
    And no sync is triggered on load (content unchanged)

  Scenario: Word count updates after sync
    Given the note has 10 required sections and 3 are filled
    When the user fills a 4th required section
    And the auto-sync completes
    Then the progress indicator updates to reflect 4 of 10 required sections filled

  Scenario: Empty content is not synced
    Given the note model is empty
    When onContentChanged is called with empty content
    Then no request is sent

  Scenario: Cancel stops pending debounce
    Given a content change was made
    When cancel is called before the debounce fires
    Then no request is sent
