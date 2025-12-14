# HRI2026 Paper Improvement Plan

## Key Clarifications

### Reviewer Feedback Assessment
1. **Confounded design critique is off-base**: Baseline was incapable of continuous behavior and limited in coverage *by design*. Our method improves on both. For a pilot LBR, independent factor evaluation is not expected.
2. **Study size comments are valid**: Reframe as pilot/exploratory study.
3. **Inter-annotator agreement**: Valid concern but we only had 1 annotator - acknowledge in limitations.
4. **GenEM comparison**: GenEM requires explicit instructions ("look excited") and translates to motion code. Our approach INFERS appropriate expression from speech content without explicit labels. GenEM also doesn't address voice/prosody coordination.

### Relevant New Citations
- **Galatolo & Winkle 2025**: Simultaneous text+gesture with small LMs. Focuses on computational efficiency, not voice coordination. Different problem scope.
- **TAACo (Patel & Chernova 2024)**: Strong empirical evidence of individual preference diversity (Kappa=0.23). Directly supports our finding about frequency/intensity preferences varying by individual.

---

## Priority-Ordered Changes

### 1. Reframe RQ2 (HIGHEST PRIORITY)
**Current**: "Does holistic LLM generation match or exceed heuristic mappings for perceived voice and physical expressivity?"
**Proposed**: "Can holistic LLM generation produce coordinated, contextually-appropriate behavior across voice and physical modalities?"

This shifts from comparison to quality/appropriateness assessment.

### 2. Reframe Abstract & Conclusion (HIGH PRIORITY)
**Key insight to emphasize**: LLM-based generation is viable for expressive behavior, BUT appropriate expression varies along:
- Voice style continuum (performer ↔ narrator)
- Physical expression continuum (frequency × intensity)
- Task context and user preferences

**Abstract changes**:
- Lead with viability finding (70% preference)
- Frame quantitative results as "pilot study trends"
- Conclude with stylistic dimensions insight as main contribution

**Conclusion changes**:
- Open with positive viability result
- Main contribution: discovery of stylistic dimensions
- Future work: preference-aware parameterization

### 3. Replace Processing Pipeline with Prompt (HIGH PRIORITY)
**Cut**: Section 3.2.2 processing pipeline (5 bullets, ~6-8 lines)
**Add**: Abbreviated behavior timeline prompt showing:
- How dialog is analyzed for emotion/topic
- How voice genres and routines are selected
- Key insight: semantic inference, not explicit labels

### 4. Streamline Evaluation Section (MEDIUM PRIORITY)
**Cut**:
- Power analysis discussion (N=44 target not reached)
- Redundant prose repeating Table 1 values
- Bonferroni correction details

**Add**:
- "Pilot study" framing
- Lead with qualitative preference (70%)
- Move statistics to table, prose for interpretation

### 5. Acknowledge Limitations Honestly (MEDIUM PRIORITY)
Add to Limitations:
- "Single annotator coded qualitative data"
- Keep study size acknowledgment
- Remove defensive language

### 6. Clarify GenEM Differentiation (LOW PRIORITY if space)
In Related Work, clarify: "GenEM requires explicit expression instructions... Our approach infers expression directly from speech semantic content."

### 7. Add TAACo/Galatolo Citations (LOW PRIORITY if space)
- TAACo: cite as evidence for individual preference variation
- Galatolo: cite as concurrent work on multimodal coordination (different scope)

---

## Space Budget

### Cuts (~15-20 lines)
- Processing pipeline bullets: ~6 lines
- Power analysis prose: ~4 lines
- Redundant Table 1 prose: ~3 lines
- Verbose evaluation setup: ~3 lines

### Additions (~15-20 lines)
- Abbreviated prompt (code block): ~8-10 lines
- Reframed abstract (net ~same)
- Reframed conclusion (net ~same)
- Limitation acknowledgments: ~2 lines

### Net: Approximately space-neutral

---

## Concrete Edits

### File: `/Users/eric/git/HRI2026/drafts/HRI2026.qmd`

#### Abstract (lines 79-80)
- Add "pilot study" framing
- Lead with 70% preference finding
- Emphasize stylistic dimensions as main contribution

#### RQ2 (line 100)
Change from:
```
- **RQ2 (Semantic Alignment)**: Does holistic LLM generation match or exceed heuristic mappings for perceived voice and physical expressivity?
```
To:
```
- **RQ2 (Coordination)**: Does holistic LLM generation produce coordinated, contextually-appropriate multimodal expression?
```

#### Section 3.2.2 Processing Pipeline (lines 163-169)
Replace 5-item pipeline with abbreviated prompt showing semantic inference

#### Evaluation Section (lines 186-227)
- Remove power analysis (Bonferroni, N=44 target)
- Reframe as "pilot study"
- Lead with qualitative findings

#### Results Section (lines 239-243)
- Frame positively: "trending improvements suggest..." rather than "neither reached significance"
- Emphasize 70% preference as primary finding

#### Limitations (lines 277-279)
Add: "Qualitative coding was performed by a single researcher."

#### Conclusion (lines 281-283)
- Open with viability result
- Emphasize stylistic dimensions as contribution
- Future: preference-aware parameterization

### File: `/Users/eric/git/HRI2026/drafts/references.bib`
Add citations if space permits:
- galatolo2025simultaneous
- patel2024taaco

---

## Execution Order

1. Edit RQ2 (quick, high impact)
2. Reframe abstract (high impact)
3. Replace processing pipeline with prompt
4. Streamline evaluation section
5. Reframe results/conclusion
6. Add limitation acknowledgments
7. Add new citations if space permits
8. Render and verify page count
9. Iterate if over/under
