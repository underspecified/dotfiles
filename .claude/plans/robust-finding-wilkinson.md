# Survey Form "No Consent" Screen Bug - Diagnosis and Fix

## Root Cause Identified

The bug is **NOT in the code** - it's a missing manual configuration in the Google Forms UI.

### The Problem

The form structure has 6 sections:
1. Consent
2. About You (Demographics)
3. Video (instructions)
4. RateVideo (questions for each video)
5. Conclusion (final questions)
6. No Consent (terminal screen for non-consenters)

The consent question correctly navigates:
- "Yes I consent" → NEXT_SECTION (continues to Section 2)
- "No I do not consent" → Jump to Section 6 (No Consent)

**However**, after Section 5 (Conclusion), the form has no explicit "After section" navigation set. Google Forms defaults to showing the next section in order, which is Section 6 (No Consent).

This is documented in the code at `create_survey_forms.js:566-569`:
```javascript
// NOTE: Google Forms REST API does not support setting "After section" navigation
// on pageBreakItems (only Apps Script does). The Conclusion section will show the
// No Consent section after it. You must manually set "After Section 5 -> Submit form"
// in the Google Forms UI
```

### Why This Wasn't Set Initially

The Google Forms **REST API** (used by the script) cannot programmatically configure "After section" navigation for page breaks. Only Google Apps Script can do this, but the project uses the REST API.

## Solution: Manual UI Fix (Zero Data Loss Risk)

### Steps to Fix Form A:

1. Open Google Form A in edit mode:
   https://docs.google.com/forms/d/1zO-Ca8zmXOgEBbCFtwU8lOzc9rHnCzFuaja7x6uomjY/edit

2. Scroll to **Section 5 (Conclusion)** - this is the section with:
   - "What differences did you notice..."
   - "Please share any other thoughts..."

3. Click the **three-dot menu (⋮)** at the bottom-right of the Conclusion section header

4. Select **"After section 5"** (or similar wording like "Go to section based on answer")

5. Change from "Continue to next section" to **"Submit form"**

### Steps to Fix Form B:

1. Open Google Form B in edit mode:
   https://docs.google.com/forms/d/1pIdW32TochNg7TseORFgSl1yXP1lNa4jHSyRN8qfhww/edit

2. Repeat steps 2-5 above

## Data Safety Confirmation

This fix is **100% safe** for existing responses:
- We are NOT modifying questions, options, or section structure
- We are NOT deleting any sections
- We are only changing navigation flow (where the form goes after Conclusion)
- Existing responses are stored in the linked Google Sheet and are unaffected by navigation changes
- The response data is already correctly captured before participants see the bug

## Verification

After making the change:
1. Preview the form (eye icon)
2. Complete the survey with "Yes I consent"
3. Verify that after the Conclusion section, you see "Submit" or a thank you message
4. Verify that the No Consent section is NOT shown

## Prevention for Future

Update `create_survey_forms.js` to add a more prominent warning after form creation, reminding the user to manually configure this setting. The code already has a note, but it could be more visible in the console output.
